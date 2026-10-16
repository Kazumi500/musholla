import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'signals.dart';

/// Tabel tunggal `scans`: sekaligus antrean offline dan riwayat lokal.
class AppDb {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'absensi_sholat.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            nisn TEXT NOT NULL,
            scanned_by TEXT NOT NULL,
            point TEXT NOT NULL,
            result TEXT NOT NULL,
            message TEXT NOT NULL,
            student_name TEXT,
            student_grade TEXT,
            at INTEGER NOT NULL,
            pending INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_scans_at ON scans(at)');
        await db.execute('CREATE INDEX idx_scans_pending ON scans(pending)');
      },
    );
    return _db!;
  }

  static int get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }

  static Future<int> insert(ScanRow row) async {
    final db = await _database;
    final id = await db.insert('scans', row.toMap());
    await refreshSignals();
    return id;
  }

  static Future<void> markSynced(
    int id, {
    required String result,
    required String message,
    String? name,
    String? grade,
  }) async {
    final db = await _database;
    await db.update(
      'scans',
      {
        'result': result,
        'message': message,
        'student_name': name,
        'student_grade': grade,
        'pending': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshSignals();
  }

  static Future<void> markFailed(int id, String message) async {
    final db = await _database;
    await db.update(
      'scans',
      {'result': 'gagal', 'message': message, 'pending': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshSignals();
  }

  static Future<void> failPendingFor(String sessionId, String message) async {
    final db = await _database;
    await db.update(
      'scans',
      {'result': 'gagal', 'message': message, 'pending': 0},
      where: 'session_id = ? AND pending = 1',
      whereArgs: [sessionId],
    );
    await refreshSignals();
  }

  static Future<List<ScanRow>> today() async {
    final db = await _database;
    final rows = await db.query(
      'scans',
      where: 'at >= ?',
      whereArgs: [_todayStart],
      orderBy: 'at DESC, id DESC',
    );
    return rows.map(ScanRow.fromMap).toList();
  }

  static Future<List<ScanRow>> pendingRows() async {
    final db = await _database;
    final rows = await db.query(
      'scans',
      where: 'pending = 1',
      orderBy: 'at ASC, id ASC',
    );
    return rows.map(ScanRow.fromMap).toList();
  }

  static Future<int> pendingCountFor(String sessionId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM scans WHERE pending = 1 AND session_id = ?',
      [sessionId],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  static Future<void> refreshSignals() async {
    final db = await _database;
    final pending =
        (await db.rawQuery('SELECT COUNT(*) AS n FROM scans WHERE pending = 1'))
                .first['n']
            as int? ??
        0;
    final today =
        (await db.rawQuery('SELECT COUNT(*) AS n FROM scans WHERE at >= ?', [
              _todayStart,
            ])).first['n']
            as int? ??
        0;
    final hadir =
        (await db.rawQuery(
              "SELECT COUNT(*) AS n FROM scans WHERE at >= ? AND result = 'hadir'",
              [_todayStart],
            )).first['n']
            as int? ??
        0;
    Signals.pending.value = pending;
    Signals.todayTotal.value = today;
    Signals.todayHadir.value = hadir;
  }
}
