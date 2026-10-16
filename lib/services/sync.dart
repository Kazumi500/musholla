import 'dart:async';

import 'api.dart';
import 'db.dart';
import 'signals.dart';
import 'store.dart';

/// Pengirim antrean offline: berjalan sendiri tiap 15 detik (sama seperti web),
/// berurutan, dan berhenti begitu jaringan putus supaya sisa antrean aman.
class Sync {
  static Timer? _timer;
  static bool _busy = false;

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => flush());
    flush();
  }

  static Future<void> flush() async {
    if (_busy) return;
    _busy = true;
    try {
      final items = await AppDb.pendingRows();
      if (items.isEmpty) return;
      final sessions = Store.sessions();
      for (final item in items) {
        final i = sessions.indexWhere((s) => s.id == item.sessionId);
        if (i < 0) {
          await AppDb.markFailed(item.id!, 'Sesi sudah dihapus dari aplikasi');
          continue;
        }
        final s = sessions[i];
        final res = await ScanApi.submit(s, nisn: item.nisn, scannedBy: item.scannedBy, point: item.point);
        if (res.kind == 'ok') {
          final j = res.json ?? const <String, dynamic>{};
          final student = j['student'] as Map<String, dynamic>?;
          await AppDb.markSynced(
            item.id!,
            result: (j['result'] as String?) ?? 'hadir',
            message: (j['message'] as String?) ?? '',
            name: student?['name'] as String?,
            grade: student?['grade'] as String?,
          );
          Signals.online.value = true;
          await Store.upsertSession(s); // simpan cookie/kunci terbaru
        } else if (res.kind == 'notfound') {
          Signals.online.value = true;
          await AppDb.markFailed(item.id!, 'Sesi tidak aktif di server');
        } else if (res.kind == 'network') {
          Signals.online.value = false;
          break;
        } else {
          Signals.online.value = true;
          break;
        }
      }
    } finally {
      _busy = false;
    }
  }
}
