import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musholla/theme.dart';

void main() {
  // Bug "putih di atas putih": gaya teks tanpa warna digambar putih oleh
  // mesin render. Semua gaya tema wajib punya warna eksplisit.
  test('setiap gaya teks tema punya warna eksplisit', () {
    final text = buildAppTheme().textTheme;
    final styles = <String, TextStyle?>{
      'displayLarge': text.displayLarge,
      'displayMedium': text.displayMedium,
      'displaySmall': text.displaySmall,
      'headlineLarge': text.headlineLarge,
      'headlineMedium': text.headlineMedium,
      'headlineSmall': text.headlineSmall,
      'titleLarge': text.titleLarge,
      'titleMedium': text.titleMedium,
      'titleSmall': text.titleSmall,
      'bodyLarge': text.bodyLarge,
      'bodyMedium': text.bodyMedium,
      'bodySmall': text.bodySmall,
      'labelLarge': text.labelLarge,
      'labelMedium': text.labelMedium,
      'labelSmall': text.labelSmall,
    };
    styles.forEach((name, style) {
      expect(style, isNotNull, reason: '$name tidak ada');
      expect(style!.color, isNotNull, reason: '$name tanpa warna');
    });
  });

  test('sakelar: jempol kontras dengan rel di kedua keadaan', () {
    final sw = buildAppTheme().switchTheme;
    expect(sw.thumbColor!.resolve({WidgetState.selected}), Colors.white);
    expect(sw.trackColor!.resolve({WidgetState.selected}), AppColors.primary);
    expect(sw.thumbColor!.resolve({}), AppColors.muted);
    expect(sw.trackColor!.resolve({}), AppColors.outline);
  });

  testWidgets('teks tanpa warna tampil dengan warna ink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Text('Contoh', style: manrope(26, FontWeight.w700)),
        ),
      ),
    );
    final ctx = tester.element(find.text('Contoh'));
    final resolved = DefaultTextStyle.of(ctx).style
        .merge(tester.widget<Text>(find.text('Contoh')).style);
    expect(resolved.color, AppColors.ink);
  });
}
