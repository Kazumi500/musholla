import 'package:flutter/material.dart';

import '../theme.dart';

/// Gaya kartu hasil per jenis hasil (warna mengikuti tabel status di DESIGN.md).
class ResultStyle {
  final String title;
  final String short;
  final String detail;
  final IconData icon;
  final Color bg;
  final Color line;
  final Color ink;
  const ResultStyle(this.title, this.short, this.detail, this.icon, this.bg, this.line, this.ink);
}

const _styles = <String, ResultStyle>{
  'hadir': ResultStyle('HADIR BERJAMAAH', 'HADIR', 'Tercatat di server', Icons.check_rounded,
      AppColors.hadirBg, AppColors.hadirLine, AppColors.hadirInk),
  'duplikat': ResultStyle('SUDAH TERCATAT', 'SUDAH', 'Tidak dihitung dobel', Icons.done_all_rounded,
      AppColors.dupBg, AppColors.dupLine, AppColors.dupInk),
  'non_muslim': ResultStyle('NON-MUSLIM (BEBAS)', 'NON-MUSLIM', 'Dispensasi sholat', Icons.menu_book_rounded,
      AppColors.nmBg, AppColors.nmLine, AppColors.nmInk),
  'belum_terdaftar': ResultStyle('TIDAK TERDAFTAR', 'TIDAK ADA', 'NISN tidak dikenal', Icons.person_off_rounded,
      AppColors.errBg, AppColors.errLine, AppColors.errInk),
  'invalid': ResultStyle('NISN TIDAK VALID', 'INVALID', 'Bukan 6 sampai 20 digit angka', Icons.error_outline_rounded,
      AppColors.errBg, AppColors.errLine, AppColors.errInk),
  'sesi_ditutup': ResultStyle('SESI DITUTUP', 'DITUTUP', 'Sudah ditutup admin', Icons.lock_rounded,
      AppColors.closedBg, AppColors.closedLine, AppColors.closedInk),
  'token_error': ResultStyle('SESI TIDAK AKTIF', 'NONAKTIF', 'Minta QR baru dari admin', Icons.link_off_rounded,
      AppColors.errBg, AppColors.errLine, AppColors.errInk),
  'offline': ResultStyle('DISIMPAN DI ANTREAN', 'ANTREAN', 'Terkirim otomatis saat jaringan ada',
      Icons.cloud_upload_outlined, AppColors.offBg, AppColors.offLine, AppColors.offInk),
  'gagal': ResultStyle('GAGAL TERKIRIM', 'GAGAL', 'Coba kirim ulang dari Riwayat', Icons.cloud_off_rounded,
      AppColors.errBg, AppColors.errLine, AppColors.errInk),
};

ResultStyle styleFor(String result) => _styles[result] ?? _styles['invalid']!;

String two(int n) => n.toString().padLeft(2, '0');
String clockText(DateTime d) => '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

class ResultCard extends StatelessWidget {
  final String result;
  final String message;
  final String? studentName;
  final String? studentGrade;
  final String nisn;
  final DateTime at;

  const ResultCard({
    super.key,
    required this.result,
    required this.message,
    this.studentName,
    this.studentGrade,
    required this.nisn,
    required this.at,
  });

  @override
  Widget build(BuildContext context) {
    final st = styleFor(result);
    final middle = studentName != null && studentName!.isNotEmpty
        ? studentName!
        : (message.isNotEmpty ? message : st.detail);
    final sub = studentName != null && studentName!.isNotEmpty
        ? '${studentGrade ?? '-'} · NISN $nisn'
        : (nisn.isNotEmpty ? 'NISN $nisn' : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: st.line, width: 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: st.line, shape: BoxShape.circle),
            child: Icon(st.icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.title, style: manrope(12.5, FontWeight.w700, color: st.ink, spacing: 0.4)),
                const SizedBox(height: 2),
                Text(middle, style: manrope(18.5, FontWeight.w800, color: st.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(sub, style: inter(12, FontWeight.w500, color: st.ink.withValues(alpha: 0.85)).copyWith(fontFeatures: tabular)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(clockText(at), style: inter(11.5, FontWeight.w600, color: st.ink.withValues(alpha: 0.7)).copyWith(fontFeatures: tabular)),
        ],
      ),
    );
  }
}
