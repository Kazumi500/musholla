/// Fungsi murni untuk membaca balasan server dan QR. Sengaja tanpa state
/// supaya mudah diuji (lihat test/parsing_test.dart).
library;

final RegExp _nisnRe = RegExp(r'^[0-9]{6,20}$');

bool isNisn(String value) => _nisnRe.hasMatch(value.trim());

/// QR dari panel admin berisi URL lengkap: http://host/s/{token}
Uri? parseSessionQr(String raw) {
  final m = RegExp(r'^(https?://[^\s/]+)/s/([A-Za-z0-9_-]+)/*$').firstMatch(raw.trim());
  if (m == null) return null;
  return Uri.parse('${m.group(1)}/s/${m.group(2)}');
}

String? extractCsrf(String html) {
  final m = RegExp(r'''name="csrf-token"\s+content="([^"]+)"''').firstMatch(html) ??
      RegExp(r'''content="([^"]+)"\s+name="csrf-token"''').firstMatch(html);
  return m?.group(1);
}

/// Judul halaman server: "Kamera Scan Dzuhur — Absensi Sholat".
String? extractSessionName(String html) {
  final m = RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
  if (m == null) return null;
  var t = htmlDecode(m.group(1)!.trim());
  t = t.replaceFirst(RegExp(r'^Kamera Scan\s+', caseSensitive: false), '');
  t = t.replaceFirst(RegExp(r'\s*[—–]\s*Absensi Sholat$', caseSensitive: false), '');
  t = t.replaceFirst(RegExp(r'\s+-\s+Absensi Sholat$', caseSensitive: false), '');
  t = t.trim();
  if (t.isEmpty || t.toLowerCase() == 'absensi sholat') return null;
  return t;
}

/// Beberapa Set-Cookie digabung koma oleh klien HTTP, padahal Expires juga
/// mengandung koma. Pecah hanya pada koma yang diikuti "nama=".
Map<String, String> parseSetCookieHeader(String raw) {
  final out = <String, String>{};
  for (final part in raw.split(RegExp(r',(?=\s*[A-Za-z0-9_\-]+=)'))) {
    final pair = part.split(';').first.trim();
    final eq = pair.indexOf('=');
    if (eq <= 0) continue;
    out[pair.substring(0, eq).trim()] = pair.substring(eq + 1).trim();
  }
  return out;
}

String htmlDecode(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#039;', "'")
    .replaceAll('&#39;', "'");
