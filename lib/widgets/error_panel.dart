import 'package:flutter/material.dart';

import '../theme.dart';

/// Panel saat data lokal tidak terbaca, dengan tombol coba ulang.
class ErrorPanel extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.errLine,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: inter(16, FontWeight.w400, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
