import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'add_session.dart';

/// Layar pertama (belum ada sesi): sambungkan aplikasi ke server lewat QR admin.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    final s = await addSessionByQr(context);
    if (!mounted) return;
    setState(() => _busy = false);
    if (s != null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.dark,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Absensi Sholat', style: manrope(26, FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'Pemindai kartu siswa untuk petugas OSIS di gerbang musholla.',
                  style: inter(
                    16,
                    FontWeight.w400,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                const _Step(
                  1,
                  'Minta QR sesi ke admin',
                  'Admin membuka halaman QR sesi di panel, lalu pilih sesi yang sedang berjalan.',
                ),
                const _Step(
                  2,
                  'Pindai QR-nya',
                  'Tekan tombol di bawah, lalu arahkan kamera ke QR tersebut.',
                ),
                const _Step(
                  3,
                  'Mulai pindai kartu siswa',
                  'Nama sesi terbaca otomatis. Setelah ini tinggal memindai seperti biasa.',
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: _busy ? null : _start,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(_busy ? 'Memproses...' : 'Pindai QR dari admin'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Tidak ada yang berubah di panel admin sekolah.',
                    style: inter(12, FontWeight.w400, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  const _Step(this.number, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: manrope(20, FontWeight.w700, color: AppColors.goldInk),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: inter(16, FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: inter(
                    14,
                    FontWeight.w400,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
