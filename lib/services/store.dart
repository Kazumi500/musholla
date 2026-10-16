import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Penyimpanan ringan: daftar sesi, gerbang harian, dan preferensi umpan balik.
class Store {
  static late SharedPreferences _p;

  static const _kSessions = 'sessions';
  static const _kActive = 'active_session';
  static const _kGate = 'gate';
  static const _kSound = 'sound_on';
  static const _kVibe = 'vibe_on';
  static const _kPrefillName = 'prefill_name';
  static const _kPrefillPoint = 'prefill_point';

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static List<ScanSession> sessions() {
    final raw = _p.getStringList(_kSessions) ?? const [];
    final out = <ScanSession>[];
    for (final s in raw) {
      try {
        out.add(ScanSession.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // lewati data rusak, jangan sampai aplikasi gagal buka
      }
    }
    return out;
  }

  static Future<void> saveSessions(List<ScanSession> list) =>
      _p.setStringList(_kSessions, [for (final s in list) jsonEncode(s.toJson())]);

  static Future<void> upsertSession(ScanSession s) async {
    final list = sessions();
    final i = list.indexWhere((x) => x.id == s.id);
    if (i >= 0) {
      list[i] = s;
    } else {
      list.add(s);
    }
    await saveSessions(list);
  }

  static Future<void> removeSession(String id) async {
    final list = sessions()..removeWhere((s) => s.id == id);
    await saveSessions(list);
    if (_p.getString(_kActive) == id) {
      await _p.remove(_kActive);
    }
  }

  static String? activeId() => _p.getString(_kActive);

  static ScanSession? activeSession() {
    final list = sessions();
    if (list.isEmpty) return null;
    final id = _p.getString(_kActive);
    return list.firstWhere((s) => s.id == id, orElse: () => list.first);
  }

  static Future<void> setActive(String id) => _p.setString(_kActive, id);

  static GateState? gateToday() {
    final raw = _p.getString(_kGate);
    if (raw == null) return null;
    try {
      final g = GateState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return g.date == todayStr() ? g : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGate(GateState g) async {
    await _p.setString(_kGate, jsonEncode(g.toJson()));
    await _p.setString(_kPrefillName, g.name);
    await _p.setString(_kPrefillPoint, g.point);
  }

  static String prefillName() => _p.getString(_kPrefillName) ?? '';
  static String prefillPoint() => _p.getString(_kPrefillPoint) ?? 'Titik 1';

  static String todayStr() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool soundOn() => _p.getBool(_kSound) ?? true;
  static Future<void> setSoundOn(bool v) => _p.setBool(_kSound, v);
  static bool vibeOn() => _p.getBool(_kVibe) ?? true;
  static Future<void> setVibeOn(bool v) => _p.setBool(_kVibe, v);
}
