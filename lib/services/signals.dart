import 'package:flutter/foundation.dart';

/// Sinyal lintas layar: antrean, hitungan hari ini, status jaringan server.
class Signals {
  Signals._();

  static final ValueNotifier<int> pending = ValueNotifier<int>(0);
  static final ValueNotifier<int> todayHadir = ValueNotifier<int>(0);
  static final ValueNotifier<int> todayTotal = ValueNotifier<int>(0);
  static final ValueNotifier<bool> online = ValueNotifier<bool>(true);
}
