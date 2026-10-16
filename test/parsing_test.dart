import 'package:flutter_test/flutter_test.dart';
import 'package:musholla/services/parsing.dart';

void main() {
  group('isNisn', () {
    test('menerima 6 sampai 20 digit', () {
      expect(isNisn('123456'), isTrue);
      expect(isNisn('00123456789012345678'), isTrue);
      expect(isNisn('  123456  '), isTrue);
    });

    test('menolak yang lain', () {
      expect(isNisn('12345'), isFalse);
      expect(isNisn('123456789012345678901'), isFalse);
      expect(isNisn('12345a'), isFalse);
      expect(isNisn(''), isFalse);
      expect(isNisn('NISN:123456'), isFalse);
    });
  });

  group('parseSessionQr', () {
    test('membaca URL sesi dari QR admin', () {
      final uri = parseSessionQr('http://192.168.1.50/s/AbCd1234');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'http');
      expect(uri.authority, '192.168.1.50');
      expect(uri.pathSegments, ['s', 'AbCd1234']);
    });

    test('menerima https, garis miring di akhir, dan spasi', () {
      expect(
        parseSessionQr('  https://absensi.sekolah.id/s/Tok3n_X  '),
        isNotNull,
      );
      expect(parseSessionQr('http://10.0.0.2:8000/s/abcd/'), isNotNull);
    });

    test('menolak QR kartu siswa dan teks lain', () {
      expect(parseSessionQr('1234567890'), isNull);
      expect(parseSessionQr('http://192.168.1.50/kartu/AbCd'), isNull);
      expect(parseSessionQr(''), isNull);
    });
  });

  group('extractCsrf', () {
    test('membaca meta csrf-token', () {
      const html = '<head><meta name="csrf-token" content="abc123XYZ"></head>';
      expect(extractCsrf(html), 'abc123XYZ');
    });

    test('menerima urutan atribut terbalik', () {
      const html = '<meta content="tok3n" name="csrf-token">';
      expect(extractCsrf(html), 'tok3n');
    });

    test('null kalau tidak ada', () {
      expect(extractCsrf('<html></html>'), isNull);
    });
  });

  group('extractSessionName', () {
    test('membaca nama dari judul halaman (dash panjang)', () {
      const html = '<title>Kamera Scan DZUHUR — Absensi Sholat</title>';
      expect(extractSessionName(html), 'DZUHUR');
    });

    test('tanpa akhiran merek', () {
      const html = '<title>Kamera Scan Ashar</title>';
      expect(extractSessionName(html), 'Ashar');
    });

    test('menerjemahkan entitas HTML', () {
      const html =
          '<title>Kamera Scan Jum&#039;at &amp; Dzuhur — Absensi Sholat</title>';
      expect(extractSessionName(html), "Jum'at & Dzuhur");
    });

    test('null kalau judul kosong atau cuma nama aplikasi', () {
      expect(extractSessionName('<title>Absensi Sholat</title>'), isNull);
      expect(extractSessionName('<title></title>'), isNull);
      expect(extractSessionName('<html></html>'), isNull);
    });
  });

  group('parseSetCookieHeader', () {
    test('memisah dua cookie yang digabung koma, termasuk Expires ber-koma', () {
      const raw =
          'XSRF-TOKEN=abc%3D; expires=Sat, 17 Oct 2026 01:00:00 GMT; path=/; samesite=lax, '
          'laravel_session=eyJpdiI6IkxhbA%3D%3D; expires=Sat, 17 Oct 2026 01:00:00 GMT; path=/; httponly';
      final map = parseSetCookieHeader(raw);
      expect(map['XSRF-TOKEN'], 'abc%3D');
      expect(map['laravel_session'], 'eyJpdiI6IkxhbA%3D%3D');
    });

    test('satu cookie tanpa atribut', () {
      expect(parseSetCookieHeader('a=b'), {'a': 'b'});
    });

    test('aman pada input kosong', () {
      expect(parseSetCookieHeader(''), isEmpty);
    });
  });

  group('htmlDecode', () {
    test('memulihkan entitas umum', () {
      expect(htmlDecode('a&amp;b&lt;c&gt;d&quot;e&#039;f'), 'a&b<c>d"e\'f');
    });
  });
}
