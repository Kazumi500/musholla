import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../services/signals.dart';
import '../services/store.dart';
import '../services/sync.dart';
import '../theme.dart';
import '../widgets/error_panel.dart';
import '../widgets/result_card.dart';

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

  String _subtitle(ScanRow r) {
    final parts = <String>[
      if (r.studentGrade != null && r.studentGrade!.isNotEmpty) r.studentGrade!,
      _sessionNames[r.sessionId] ?? '',
      if (r.pending) 'menunggu jaringan',
    ]..removeWhere((s) => s.isEmpty);
    return parts.isEmpty ? 'NISN ${r.nisn}' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                        style: manrope(23, FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dari HP ini saja, bukan seluruh sekolah.',
                        style: inter(
                          13,
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
                    borderRadius: BorderRadius.circular(14),
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
                            13,
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
                                        15,
                                        FontWeight.w600,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hasil scan muncul di sini, tetap tersimpan walau jaringan lepas.',
                                      textAlign: TextAlign.center,
                                      style: inter(
                                        13,
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
                            itemBuilder: (context, i) => _rowTile(_rows[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(ScanRow r) {
    final st = styleFor(r.result);
    final at = DateTime.fromMillisecondsSinceEpoch(r.at);
    final title = (r.studentName != null && r.studentName!.isNotEmpty)
        ? r.studentName!
        : (r.message.isNotEmpty ? r.message : 'NISN ${r.nisn}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Text(
              '${two(at.hour)}:${two(at.minute)}',
              style: inter(
                12.5,
                FontWeight.w600,
                color: AppColors.muted,
              ).copyWith(fontFeatures: tabular),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: inter(14.5, FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(r),
                    style: inter(12, FontWeight.w400, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: st.bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: st.line, width: 1),
              ),
              child: Text(
                st.short,
                style: inter(10.5, FontWeight.w700, color: st.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
