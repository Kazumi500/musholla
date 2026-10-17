import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/db.dart';
import 'services/feedback.dart';
import 'services/store.dart';
import 'services/sync.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppSystemUi.dark);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Store.init();
  await ScanFeedback.init();
  await AppDb.refreshSignals();
  Sync.start();
  runApp(const AbsensiSholatApp());
}

class AbsensiSholatApp extends StatelessWidget {
  const AbsensiSholatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Sholat',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
