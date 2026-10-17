import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/db.dart';
import '../services/signals.dart';
import '../services/store.dart';
import '../services/sync.dart';
import '../theme.dart';
import '../widgets/error_panel.dart';
import '../widgets/result_card.dart';
import '../widgets/scan_tile.dart';

/// Isi tab "Riwayat": pindaian hari ini dari HP ini, plus tombol sinkron.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<ScanRow> _rows = const [];
  Map<String, String> _sessionNames = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Signals.todayTotal.addListener(_reload);
    Signals.pending.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    Signals.todayTotal.removeListener(_reload);
    Signals.pending.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final rows = await AppDb.today();
      final names = {for (final s in Store.sessions()) s.id: s.name};
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _sessionNames = names;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Riwayat tidak bisa dibaca dari penyimpanan. Coba lagi.';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _reload();
  }

  Future<void> _syncNow() async {
    await Sync.flush();
    if (!mounted) return;
    final n = Signals.pending.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n == 0
              ? 'Semua antrean sudah terkirim.'
              : 'Masih ada $n antrean. Coba lagi sebentar lagi.',
        ),
      ),
    );
    await _reload();
  }

  /// Kirim ulang baris "gagal": konfirmasi singkat, antrekan lagi, lalu coba
  /// kirim sekarang; hasilnya dilaporkan supaya petugas tahu kelanjutannya.
  Future<void> _retryRow(ScanRow row) async {
    final who = (row.studentName?.isNotEmpty ?? false)
        ? row.studentName!
        : 'NISN ${row.nisn}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim ulang?'),
        content: Text('Pindaian $who akan dicoba dikirim ke server lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kirim ulang'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppDb.requeue(row.id!);
    await Sync.flush();
    if (!mounted) return;
    final after = await AppDb.byId(row.id!);
    if (!mounted) return;
    final text = after == null
        ? 'Baris itu tidak ada lagi di riwayat.'
        : after.result == 'gagal'
        ? (after.message.isEmpty
              ? 'Masih gagal terkirim.'
              : 'Masih gagal: ${after.message}.')
        : after.result == 'offline'
        ? 'Masih menunggu jaringan. Nanti dicoba otomatis.'
        : 'Terkirim: ${styleFor(after.result).title}.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.dark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat hari ini',
                          style: manrope(26, FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dari HP ini saja, bukan seluruh sekolah.',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _syncNow,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Sinkron'),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: Signals.pending,
              builder: (context, pending, child) {
                if (pending == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.offBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.offLine.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 18,
                          color: AppColors.offInk,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pending pindaian menunggu jaringan. Simpanan aman, terkirim otomatis.',
                            style: inter(
                              14,
                              FontWeight.w500,
                              color: AppColors.offInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ErrorPanel(message: _error!, onRetry: _retry)
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: _rows.isEmpty
                          ? ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    28,
                                    80,
                                    28,
                                    20,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 44,
                                        color: AppColors.muted.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Belum ada pindaian hari ini.',
                                        style: inter(
                                          16,
                                          FontWeight.w600,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hasil pindai muncul di sini, tetap tersimpan walau jaringan lepas.',
                                        textAlign: TextAlign.center,
                                        style: inter(
                                          14,
                                          FontWeight.w400,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                              itemCount: _rows.length,
                              itemBuilder: (context, i) => ScanTile(
                                row: _rows[i],
                                sessionName: _sessionNames[_rows[i].sessionId],
                                onRetry: () => _retryRow(_rows[i]),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
