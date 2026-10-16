import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'parsing.dart';

/// Hasil panggilan API. `kind`:
/// ok        -> server menjawab normal
/// network   -> tidak bisa menghubungi server (sinyal/LAN putus)
/// notfound  -> token sesi tidak dikenal atau dinonaktifkan
/// csrf      -> kunci sesi tetap ditolak setelah diambil ulang
/// server    -> server hidup tapi jawabannya di luar dugaan
class ApiOutcome {
  final String kind;
  final Map<String, dynamic>? json;
  final String? note;
  const ApiOutcome(this.kind, {this.json, this.note});
}

class ScanApi {
  static const _timeout = Duration(seconds: 8);
  static final http.Client _client = http.Client();

  static Map<String, String> _baseHeaders() => {
        'Accept-Language': 'id',
        'User-Agent': 'AbsensiSholat/1.0 (Android)',
      };

  /// Buka halaman scan di server: ambil kunci CSRF, cookie sesi, dan nama sesi.
  /// Inilah "izin masuk" yang wajib dilakukan sekali sebelum kiriman pertama.
  static Future<ApiOutcome> fetchPage(ScanSession s) async {
    try {
      final res = await _client
          .get(Uri.parse(s.pageUrl), headers: {'Accept': 'text/html', ..._baseHeaders()})
          .timeout(_timeout);
      if (res.statusCode == 404) return const ApiOutcome('notfound');
      if (res.statusCode != 200) return ApiOutcome('server', note: 'HTTP ${res.statusCode}');
      final html = utf8.decode(res.bodyBytes);
      final csrf = extractCsrf(html);
      final cookies = parseSetCookieHeader(res.headers['set-cookie'] ?? '');
      if (csrf == null || cookies.isEmpty) return const ApiOutcome('server', note: 'Halaman tidak dikenali');
      s.cookies.addAll(cookies);
      s.csrf = csrf;
      final name = extractSessionName(html);
      if (name != null && name.isNotEmpty) {
        s.name = name;
        s.nameFromServer = true;
      }
      return const ApiOutcome('ok');
    } on Exception catch (e) {
      return ApiOutcome('network', note: e.toString());
    }
  }

  /// Kirim satu pindaian. Kalau kunci kedaluwarsa (419), ambil halaman baru
  /// sekali lalu coba ulang, sama seperti halaman web.
  static Future<ApiOutcome> submit(
    ScanSession s, {
    required String nisn,
    required String scannedBy,
    required String point,
  }) async {
    if (!s.ready) {
      final pre = await fetchPage(s);
      if (pre.kind != 'ok') return pre;
    }
    try {
      var res = await _post(s, nisn: nisn, scannedBy: scannedBy, point: point);
      if (res.statusCode == 419) {
        final pre = await fetchPage(s);
        if (pre.kind != 'ok') return pre;
        res = await _post(s, nisn: nisn, scannedBy: scannedBy, point: point);
        if (res.statusCode == 419) return const ApiOutcome('csrf');
      }
      if (res.statusCode == 404) return const ApiOutcome('notfound');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return ApiOutcome('ok', json: body);
      }
      return ApiOutcome('server', note: 'HTTP ${res.statusCode}');
    } on Exception catch (e) {
      return ApiOutcome('network', note: e.toString());
    }
  }

  static Future<http.Response> _post(
    ScanSession s, {
    required String nisn,
    required String scannedBy,
    required String point,
  }) {
    return _client
        .post(
          Uri.parse(s.submitUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-TOKEN': s.csrf ?? '',
            'Cookie': s.cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
            ..._baseHeaders(),
          },
          body: jsonEncode({'nisn': nisn, 'scanned_by': scannedBy, 'point': point}),
        )
        .timeout(_timeout);
  }
}
