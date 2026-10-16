/// Titik gerbang: sama persis dengan daftar di halaman web (paritas).
class GatePoint {
  final String value;
  final String label;
  const GatePoint(this.value, this.label);
}

const gatePoints = <GatePoint>[
  GatePoint('Titik 1', 'Pintu Utama (Putra)'),
  GatePoint('Titik 2', 'Pintu Barat (Putri)'),
  GatePoint('Titik 3', 'Selasar Belakang'),
];

GatePoint gatePointOf(String value) => gatePoints.firstWhere(
  (p) => p.value == value,
  orElse: () => gatePoints.first,
);

/// Sesi absensi tersimpan: hasil scan QR dari panel admin + sesi HTTP ke server.
class ScanSession {
  String id;
  String baseUrl; // contoh: http://192.168.1.50
  String token;
  String name;
  String? csrf;
  Map<String, String> cookies;
  int lastUsedAt;
  bool nameFromServer;

  ScanSession({
    required this.id,
    required this.baseUrl,
    required this.token,
    required this.name,
    this.csrf,
    Map<String, String>? cookies,
    this.lastUsedAt = 0,
    this.nameFromServer = false,
  }) : cookies = cookies ?? {};

  bool get ready => (csrf ?? '').isNotEmpty && cookies.isNotEmpty;
  String get host => Uri.parse(baseUrl).host;
  String get pageUrl => '$baseUrl/s/$token';
  String get submitUrl => '$pageUrl/scan';

  static String idFor(String baseUrl, String token) => '$baseUrl|$token';

  Map<String, dynamic> toJson() => {
    'id': id,
    'base_url': baseUrl,
    'token': token,
    'name': name,
    'csrf': csrf,
    'cookies': cookies,
    'last_used_at': lastUsedAt,
    'name_from_server': nameFromServer,
  };

  factory ScanSession.fromJson(Map<String, dynamic> j) => ScanSession(
    id: j['id'] as String,
    baseUrl: j['base_url'] as String,
    token: j['token'] as String,
    name: j['name'] as String? ?? 'Sesi',
    csrf: j['csrf'] as String?,
    cookies: (j['cookies'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as String),
    ),
    lastUsedAt: j['last_used_at'] as int? ?? 0,
    nameFromServer: j['name_from_server'] as bool? ?? false,
  );
}

/// Identitas petugas hari ini (gerbang web menyimpan pola yang sama).
class GateState {
  String date; // yyyy-mm-dd
  String name;
  String point;

  GateState({required this.date, required this.name, required this.point});

  Map<String, dynamic> toJson() => {'date': date, 'name': name, 'point': point};
  factory GateState.fromJson(Map<String, dynamic> j) => GateState(
    date: j['date'] as String,
    name: j['name'] as String,
    point: j['point'] as String,
  );
}

/// Satu baris catatan pindaian lokal (antrean + riwayat memakai tabel yang sama).
class ScanRow {
  int? id;
  String sessionId;
  String nisn;
  String scannedBy;
  String point;
  String result;
  String message;
  String? studentName;
  String? studentGrade;
  int at;
  bool pending;

  ScanRow({
    this.id,
    required this.sessionId,
    required this.nisn,
    required this.scannedBy,
    required this.point,
    required this.result,
    required this.message,
    this.studentName,
    this.studentGrade,
    required this.at,
    this.pending = false,
  });

  Map<String, Object?> toMap() => {
    'session_id': sessionId,
    'nisn': nisn,
    'scanned_by': scannedBy,
    'point': point,
    'result': result,
    'message': message,
    'student_name': studentName,
    'student_grade': studentGrade,
    'at': at,
    'pending': pending ? 1 : 0,
  };

  factory ScanRow.fromMap(Map<String, Object?> m) => ScanRow(
    id: m['id'] as int?,
    sessionId: m['session_id'] as String,
    nisn: m['nisn'] as String,
    scannedBy: m['scanned_by'] as String,
    point: m['point'] as String,
    result: m['result'] as String,
    message: m['message'] as String,
    studentName: m['student_name'] as String?,
    studentGrade: m['student_grade'] as String?,
    at: m['at'] as int,
    pending: (m['pending'] as int? ?? 0) == 1,
  );
}
