import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'result_card.dart';

/// Satu baris pindaian: waktu, nama atau status dari tabel aplikasi, dan chip
/// status. Baris "gagal" menampilkan tombol "Kirim ulang" bila `onRetry` ada.
/// Dipakai tab Riwayat dan blok "Pindaian terakhir" di Beranda.
class ScanTile extends StatelessWidget {
  final ScanRow row;
  final String? sessionName;
  final VoidCallback? onRetry;
  const ScanTile({
    super.key,
    required this.row,
    this.sessionName,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final st = styleFor(row.result);
    final at = DateTime.fromMillisecondsSinceEpoch(row.at);
    final named = row.studentName != null && row.studentName!.isNotEmpty;
    final title = named ? row.studentName! : st.title;
    final parts = <String>[
      if (named && row.studentGrade != null && row.studentGrade!.isNotEmpty)
        row.studentGrade!,
      if (!named) 'NISN ${row.nisn}',
      sessionName ?? '',
      if (row.result == 'gagal' && row.message.isNotEmpty) row.message,
      if (row.pending) 'menunggu jaringan',
    ]..removeWhere((s) => s.isEmpty);
    final subtitle = parts.isEmpty ? 'NISN ${row.nisn}' : parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Text(
              '${two(at.hour)}:${two(at.minute)}',
              style: inter(
                12,
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
                    style: manrope(16, FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: inter(14, FontWeight.w400, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onRetry != null && row.result == 'gagal')
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: inter(14, FontWeight.w600),
                ),
                onPressed: onRetry,
                child: const Text('Kirim ulang'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: st.line),
                ),
                child: Text(
                  st.short,
                  style: inter(12, FontWeight.w600, color: st.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
