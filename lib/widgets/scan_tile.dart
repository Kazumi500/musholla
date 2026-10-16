import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'result_card.dart';

/// Satu baris pindaian: waktu, nama atau pesan, dan chip status.
/// Dipakai tab Riwayat dan blok "Pindaian terakhir" di Beranda.
class ScanTile extends StatelessWidget {
  final ScanRow row;
  final String? sessionName;
  const ScanTile({super.key, required this.row, this.sessionName});

  @override
  Widget build(BuildContext context) {
    final st = styleFor(row.result);
    final at = DateTime.fromMillisecondsSinceEpoch(row.at);
    final title = (row.studentName != null && row.studentName!.isNotEmpty)
        ? row.studentName!
        : (row.message.isNotEmpty ? row.message : 'NISN ${row.nisn}');
    final parts = <String>[
      if (row.studentGrade != null && row.studentGrade!.isNotEmpty)
        row.studentGrade!,
      sessionName ?? '',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
