import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/db.dart';
import '../services/feedback.dart';
import '../services/parsing.dart';
import '../services/signals.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/result_card.dart';
import '../widgets/sheets.dart';

class _CardData {
  final String result;
  final String message;
  final String? name;
  final String? grade;
  final String nisn;
  final DateTime at;
  const _CardData(this.result, this.message, this.name, this.grade, this.nisn, this.at);
}

/// Layar pemindai: kamera penuh, kartu hasil di atasnya, dan kendali lengkap.
/// Alur hasil mengikuti halaman web: jeda 3 detik kartu yang sama, kiriman
/// gagal masuk antrean, kunci kedaluwarsa diambil ulang otomatis.
class ScanScreen extends StatefulWidget {
  final ScanSession session;
  const ScanScreen({super.key, required this.session});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _cooldownMs = 3000;

  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final Map<String, int> _recent = {};
  final List<String> _inbox = [];
  bool _busy = false;
  bool _blockInput = false;
  bool _torch = false;
  bool _sound = true;
  bool _vibe = true;
  _CardData? _card;
  Timer? _cardTimer;
  late final GateState _gate;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _sound = Store.soundOn();
    _vibe = Store.vibeOn();
    _gate = Store.gateToday() ??
        GateState(date: Store.todayStr(), name: Store.prefillName(), point: Store.prefillPoint());
    unawaited(_warmUp());
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    _cardTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Siapkan kunci CSRF + cookie sebelum tembakan pertama, supaya scan
  /// pertama tidak perlu menunggu dua perjalanan ke server.
  Future<void> _warmUp() async {
    if (widget.session.ready) return;
    final res = await ScanApi.fetchPage(widget.session);
    if (res.kind == 'ok') {
      await Store.upsertSession(widget.session);
      Signals.online.value = true;
    } else if (res.kind == 'network') {
      Signals.online.value = false;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_blockInput || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue?.trim() ?? '';
    if (raw.isEmpty) return;
    if (_busy) {
      _inbox.add(raw);
      return;
    }
    unawaited(_process(raw));
  }

  bool _recently(String key, int now) {
    final last = _recent[key];
    return last != null && now - last < _cooldownMs;
  }

  Future<void> _process(String value) async {
    _busy = true;
    try {
      final upper = value.toUpperCase();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!isNisn(upper)) {
        if (!_recently('raw:$upper', now)) {
          _recent['raw:$upper'] = now;
          final shown = upper.length > 20 ? upper.substring(0, 20) : upper;
          _show(_CardData('invalid', 'Bukan format NISN: $shown', null, null, shown, DateTime.now()));
          await ScanFeedback.play('invalid');
        }
        return;
      }

      if (_recently(upper, now)) {
        _recent[upper] = now; // kartu masih di depan kamera: perpanjang jeda, tanpa bunyi lagi
        return;
      }
      _recent[upper] = now;

      final res = await ScanApi.submit(widget.session, nisn: upper, scannedBy: _gate.name, point: _gate.point);
      final at = DateTime.now();

      if (res.kind == 'ok') {
        final j = res.json ?? const <String, dynamic>{};
        final result = (j['result'] as String?) ?? 'hadir';
        final message = (j['message'] as String?) ?? '';
        final student = j['student'] as Map<String, dynamic>?;
        final name = student?['name'] as String?;
        final grade = student?['grade'] as String?;
        await AppDb.insert(ScanRow(
          sessionId: widget.session.id,
          nisn: upper,
          scannedBy: _gate.name,
          point: _gate.point,
          result: result,
          message: message,
          studentName: name,
          studentGrade: grade,
          at: at.millisecondsSinceEpoch,
        ));
        Signals.online.value = true;
        await Store.upsertSession(widget.session);
        _show(_CardData(result, message, name, grade, upper, at));
        await ScanFeedback.play(result);
      } else if (res.kind == 'notfound') {
        Signals.online.value = true;
        _show(_CardData('token_error', 'Sesi tidak aktif di server. Minta QR baru dari admin.', null, null, upper, at));
        await ScanFeedback.play('token_error');
      } else {
        // network / csrf / jawaban aneh: simpan ke antrean, jangan pernah buang pindaian
        await AppDb.insert(ScanRow(
          sessionId: widget.session.id,
          nisn: upper,
          scannedBy: _gate.name,
          point: _gate.point,
          result: 'offline',
          message: 'Menunggu jaringan',
          at: at.millisecondsSinceEpoch,
          pending: true,
        ));
        Signals.online.value = res.kind != 'network';
        _show(_CardData('offline', 'Masuk antrean, terkirim otomatis.', null, null, upper, at));
        await ScanFeedback.play('offline');
      }
    } finally {
      _busy = false;
      if (_inbox.isNotEmpty) {
        unawaited(_process(_inbox.removeAt(0)));
      }
    }
  }

  void _show(_CardData data) {
    _cardTimer?.cancel();
    setState(() => _card = data);
    _cardTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _card = null);
    });
  }

  Future<void> _manual() async {
    _blockInput = true;
    final nisn = await showManualNisnSheet(context);
    _blockInput = false;
    if (nisn == null) return;
    unawaited(_process(nisn));
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    try {
      await _controller.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _cameraError(error),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _round(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sesi: ${widget.session.name}',
                          style: inter(12.5, FontWeight.w600, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _round(icon: _torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, active: _torch, onTap: _toggleTorch),
                      const SizedBox(width: 8),
                      _round(icon: Icons.cameraswitch_rounded, onTap: _flipCamera),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 2.5),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 24, spreadRadius: 2)],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Arahkan kamera ke kartu siswa.', style: inter(15, FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Tidak perlu terlalu dekat.', style: inter(13, FontWeight.w400, color: Colors.white70)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _card == null
                      ? const SizedBox.shrink(key: ValueKey('kosong'))
                      : Padding(
                          key: ValueKey('kartu-${_card!.at.microsecondsSinceEpoch}'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ResultCard(
                            result: _card!.result,
                            message: _card!.message,
                            studentName: _card!.name,
                            studentGrade: _card!.grade,
                            nisn: _card!.nisn,
                            at: _card!.at,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      _round(icon: _sound ? Icons.volume_up_rounded : Icons.volume_off_rounded, active: _sound, onTap: () async {
                        setState(() => _sound = !_sound);
                        await Store.setSoundOn(_sound);
                      }),
                      const SizedBox(width: 8),
                      _round(icon: Icons.vibration_rounded, active: _vibe, onTap: () async {
                        setState(() => _vibe = !_vibe);
                        await Store.setVibeOn(_vibe);
                      }),
                      const SizedBox(width: 8),
                      _manualChip(),
                      const Spacer(),
                      _statusPill(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _round({required IconData icon, required VoidCallback onTap, bool active = false}) {
    return Material(
      color: active ? AppColors.gold : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: active ? AppColors.primaryDark : Colors.white),
        ),
      ),
    );
  }

  Widget _manualChip() {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        onTap: _manual,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dialpad_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 7),
              Text('NISN', style: inter(13, FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill() {
    return ValueListenableBuilder<int>(
      valueListenable: Signals.pending,
      builder: (context, pending, child) => ValueListenableBuilder<bool>(
        valueListenable: Signals.online,
        builder: (context, online, child) {
          if (pending == 0 && online) return const SizedBox.shrink();
          final bg = pending > 0 ? AppColors.offLine : AppColors.errLine;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              pending > 0 ? 'Antrean: $pending' : 'Terputus',
              style: inter(12, FontWeight.w600, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _cameraError(MobileScannerException error) {
    var reason = 'Kamera tidak bisa dibuka.';
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      reason = 'Izin kamera belum diberikan. Buka pengaturan Android, izinkan kamera untuk Absensi Sholat, lalu coba lagi.';
    } else if (error.errorCode == MobileScannerErrorCode.unsupported) {
      reason = 'Perangkat ini tidak mendukung pemindaian lewat kamera. Pakai input NISN manual.';
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 46),
              const SizedBox(height: 14),
              Text(reason, textAlign: TextAlign.center, style: inter(14.5, FontWeight.w400, color: Colors.white, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      try {
                        await _controller.stop();
                        await _controller.start();
                      } catch (_) {}
                    },
                    child: const Text('Coba lagi'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _manual,
                    child: const Text('Input NISN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
