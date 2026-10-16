import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/parsing.dart';
import '../services/store.dart';
import '../widgets/sheets.dart';
import 'qr_scanner_route.dart';

/// Alur menambah sesi lewat QR admin, dipakai dari setup awal dan Pengaturan.
/// Mengembalikan sesi yang siap dipakai, atau null kalau dibatalkan/gagal.
Future<ScanSession?> addSessionByQr(BuildContext context) async {
  final raw = await QrScanRoute.open(context);
  if (raw == null || !context.mounted) return null;

  final uri = parseSessionQr(raw);
  if (uri == null) {
    await showAppDialog(
      context,
      title: 'QR tidak dikenal',
      body: 'QR ini bukan QR sesi absensi. Minta admin membuka halaman QR sesi di panel.',
    );
    return null;
  }

  final base = '${uri.scheme}://${uri.authority}';
  final token = uri.pathSegments.last;
  final id = ScanSession.idFor(base, token);

  ScanSession? existing;
  for (final s in Store.sessions()) {
    if (s.id == id) {
      existing = s;
      break;
    }
  }
  final session = existing ??
      ScanSession(
        id: id,
        baseUrl: base,
        token: token,
        name: 'Sesi baru',
        lastUsedAt: DateTime.now().millisecondsSinceEpoch,
      );

  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            SizedBox(width: 16),
            Expanded(child: Text('Membaca sesi dari server...')),
          ],
        ),
      ),
    ),
  ));

  final res = await ScanApi.fetchPage(session);
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop(); // tutup dialog loading

  if (res.kind == 'notfound') {
    await showAppDialog(
      context,
      title: 'QR ditolak server',
      body: 'Sesi ini tidak dikenal atau dinonaktifkan di server. Cek dengan admin, lalu coba lagi.',
    );
    return null;
  }

  session.lastUsedAt = DateTime.now().millisecondsSinceEpoch;
  await Store.upsertSession(session);
  await Store.setActive(session.id);

  if (res.kind != 'ok' && context.mounted) {
    await showAppDialog(
      context,
      title: 'Sesi disimpan',
      body: 'Server belum bisa dihubungi sekarang. Sesi sudah disimpan dan akan diverifikasi otomatis saat jaringan tersambung.',
    );
  }
  return session;
}
