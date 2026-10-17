import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/db.dart';
import '../services/signals.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/scan_tile.dart';
import '../widgets/sheets.dart';
import 'add_session.dart';
import 'history_tab.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Rumah aplikasi: sapaan petugas di kepala hijau, ringkasan hari ini,
/// pindaian terakhir, dan bilah navigasi bawah dengan ikon QR di tengah.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<ScanSession> _sessions = const [];
  ScanSession? _active;
  List<ScanRow> _recent = const [];
  bool _gateOpened = false;

  @override
  void initState() {
    super.initState();
    _reload();
    Signals.todayTotal.addListener(_onData);
    Signals.pending.addListener(_onData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    Signals.todayTotal.removeListener(_onData);
    Signals.pending.removeListener(_onData);
    super.dispose();
  }

  /// Sinyal data berubah (pindai baru, antrean terkirim): segarkan ringkasan.
  void _onData() {
    _reload();
  }

  Future<void> _boot() async {
    await _reload();
    if (!mounted) return;
    if (_sessions.isEmpty) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SetupScreen()));
      if (!mounted) return;
      await _reload();
      return;
    }
    if (Store.gateToday() == null && !_gateOpened) {
      _gateOpened = true;
      await showGateSheet(context, blocking: true);
      if (mounted) setState(() {});
    }
  }

  Future<void> _reload() async {
    final sessions = Store.sessions();
    final active = Store.activeSession();
    List<ScanRow> recent;
    try {
      recent = (await AppDb.today()).take(3).toList();
    } catch (_) {
      recent = const [];
    }
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _active = active;
      _recent = recent;
    });
  }

  /// Pilih sesi tujuan: 1 sesi dan memang untuk scan, langsung pakai;
  /// selain itu buka daftar (juga jalan untuk menambah sesi baru).
  Future<ScanSession?> _chooseSession({required bool forScan}) async {
    final sessions = Store.sessions();
    if (sessions.isEmpty) {
      final s = await addSessionByQr(context);
      if (!mounted) return null;
      await _reload();
      return s;
    }
    if (forScan && sessions.length == 1) return sessions.first;
    final pick = await showSessionPicker(
      context,
      sessions: sessions,
      activeId: Store.activeId(),
    );
    if (!mounted || pick == null) return null;
    if (pick.addNew) {
      final s = await addSessionByQr(context);
      if (!mounted) return null;
      await _reload();
      return s;
    }
    return pick.session;
  }

  Future<void> _openScan() async {
    final target = await _chooseSession(forScan: true);
    if (target == null || !mounted) return;
    await Store.setActive(target.id);
    target.lastUsedAt = DateTime.now().millisecondsSinceEpoch;
    await Store.upsertSession(target);
    await _reload();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ScanScreen(session: target)),
    );
    if (mounted) await _reload();
  }

  Future<void> _pickSession() async {
    final target = await _chooseSession(forScan: false);
    if (target == null || !mounted) return;
    await Store.setActive(target.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _Beranda(
            active: _active,
            recent: _recent,
            sessionNames: {for (final s in _sessions) s.id: s.name},
            onScan: _openScan,
            onPickSession: _pickSession,
            onHistory: () => setState(() => _tab = 1),
            onChanged: _reload,
          ),
          const HistoryTab(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        tab: _tab,
        onTab: (i) => setState(() => _tab = i),
        onScan: _openScan,
      ),
    );
  }
}

class _Beranda extends StatelessWidget {
  final ScanSession? active;
  final List<ScanRow> recent;
  final Map<String, String> sessionNames;
  final Future<void> Function() onScan;
  final Future<void> Function() onPickSession;
  final VoidCallback onHistory;
  final Future<void> Function() onChanged;

  const _Beranda({
    required this.active,
    required this.recent,
    required this.sessionNames,
    required this.onScan,
    required this.onPickSession,
    required this.onHistory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gate = Store.gateToday();
    final name = (gate?.name.isNotEmpty ?? false)
        ? gate!.name
        : Store.prefillName();
    final point = gatePointOf(gate?.point ?? Store.prefillPoint());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.light,
      child: Column(
        children: [
          _head(context, name: name, point: point),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pills(),
                  const SizedBox(height: 18),
                  _todayCard(),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _recentBlock(),
                  ] else ...[
                    const SizedBox(height: 16),
                    _startCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kepala hijau tua: sapaan, nama petugas, dan baris titik gerbang.
  Widget _head(
    BuildContext context, {
    required String name,
    required GatePoint point,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamualaikum,',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.onPrimarySoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.isEmpty ? 'Petugas OSIS' : name,
                          style: manrope(
                            26,
                            FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                      await onChanged();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.primaryDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: InkWell(
                  customBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  onTap: () async {
                    await showGateSheet(context);
                    await onChanged();
                  },
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: AppColors.goldSoft,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${point.value} · ${point.label}',
                            style: inter(
                              14,
                              FontWeight.w600,
                              color: AppColors.goldSoft,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: AppColors.goldSoft,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: Signals.online,
          builder: (context, online, child) => _pill(
            bg: online ? AppColors.hadirBg : AppColors.errBg,
            line: online ? AppColors.hadirLine : AppColors.errLine,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? AppColors.hadirLine : AppColors.errLine,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  online ? 'Terhubung' : 'Terputus',
                  style: inter(
                    12,
                    FontWeight.w600,
                    color: online ? AppColors.hadirInk : AppColors.errInk,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onPickSession(),
          child: SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              child: _pill(
                bg: Colors.white,
                line: AppColors.outlineStrong,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sesi: ${active?.name ?? 'belum dipilih'}',
                      style: inter(12, FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: Signals.pending,
          builder: (context, pending, child) {
            if (pending == 0) return const SizedBox.shrink();
            return _QueuePulse(
              child: _pill(
                bg: AppColors.offBg,
                line: AppColors.offLine,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 15,
                      color: AppColors.offInk,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Antrean: $pending',
                      style: inter(
                        12,
                        FontWeight.w600,
                        color: AppColors.offInk,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _todayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ini, dari HP ini',
            style: inter(
              12,
              FontWeight.w600,
              color: AppColors.muted,
              spacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<int>(
            valueListenable: Signals.todayHadir,
            builder: (context, hadir, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$hadir',
                      style: manrope(
                        40,
                        FontWeight.w800,
                      ).copyWith(fontFeatures: tabular),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'siswa hadir',
                      style: inter(14, FontWeight.w500, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<int>(
                  valueListenable: Signals.todayTotal,
                  builder: (context, total, child) => Text(
                    '$total pindaian tercatat hari ini',
                    style: inter(14, FontWeight.w400, color: AppColors.muted),
                  ),
                ),
                if (hadir > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Terima kasih sudah menjaga gerbang hari ini.',
                    style: inter(14, FontWeight.w400, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pindaian terakhir',
                style: manrope(20, FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onHistory, child: const Text('Lihat semua')),
          ],
        ),
        const SizedBox(height: 6),
        for (final row in recent)
          ScanTile(row: row, sessionName: sessionNames[row.sessionId]),
      ],
    );
  }

  Widget _startCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: AppColors.goldInk,
            ),
          ),
          const SizedBox(height: 12),
          Text('Siap memindai?', style: manrope(20, FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Arahkan kamera ke kartu siswa saat antrean datang. Tidak perlu terlalu dekat.',
            style: inter(
              14,
              FontWeight.w400,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: const Text('Mulai pindai'),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required Color bg,
    required Color line,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class _BottomBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;

  const _BottomBar({
    required this.tab,
    required this.onTab,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outline)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _item(
                  icon: tab == 0 ? Icons.home_rounded : Icons.home_outlined,
                  label: 'Beranda',
                  selected: tab == 0,
                  onTap: () => onTab(0),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -16),
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.gold, width: 2.5),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black45,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onScan,
                    child: const SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _item(
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  selected: tab == 1,
                  onTap: () => onTab(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: inter(12, FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Denyut halus pil antrean (kontrak gerak DESIGN): hanya opasitas, ukuran
/// tidak berubah supaya tata letak tetap tenang. Mati saat animasi sistem
/// dimatikan.
class _QueuePulse extends StatefulWidget {
  final Widget child;
  const _QueuePulse({required this.child});

  @override
  State<_QueuePulse> createState() => _QueuePulseState();
}

class _QueuePulseState extends State<_QueuePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _fade = Tween<double>(
    begin: 1,
    end: 0.7,
  ).animate(CurvedAnimation(parent: _control, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _control.stop();
      _control.value = 0;
    } else if (!_control.isAnimating) {
      _control.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}
