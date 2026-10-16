import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/db.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/error_panel.dart';
import '../widgets/sheets.dart';
import 'add_session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ScanSession> _sessions = const [];
  Map<String, int> _pendingPer = const {};
  bool _checking = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = Store.sessions();
      final counts = <String, int>{};
      for (final s in sessions) {
        counts[s.id] = await AppDb.pendingCountFor(s.id);
      }
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _pendingPer = counts;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Data sesi tidak bisa dibaca dari penyimpanan. Coba lagi.';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  Future<void> _addSession() async {
    final s = await addSessionByQr(context);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    if (s != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sesi "${s.name}" siap dipakai.')));
    }
  }

  Future<void> _editGate() async {
    await showGateSheet(context);
    if (mounted) setState(() {});
  }

  Future<void> _checkAll() async {
    if (_checking) return;
    setState(() => _checking = true);
    var ok = 0;
    final list = Store.sessions();
    for (final s in list) {
      final res = await ScanApi.fetchPage(s);
      if (res.kind == 'ok') {
        ok++;
        await Store.upsertSession(s);
      }
    }
    if (!mounted) return;
    setState(() => _checking = false);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          list.isEmpty
              ? 'Belum ada sesi.'
              : ok == list.length
              ? 'Semua sesi (${list.length}) terhubung.'
              : '$ok dari ${list.length} sesi terhubung. Cek jaringan LAN dan QR sesinya.',
        ),
      ),
    );
  }

  Future<void> _delete(ScanSession s) async {
    final n = await AppDb.pendingCountFor(s.id);
    if (!mounted) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Hapus sesi "${s.name}"?'),
            content: Text(
              n > 0
                  ? 'Masih ada $n pindaian belum terkirim untuk sesi ini. Kalau dihapus, antrean itu tidak bisa dikirim lagi.'
                  : 'Sesi ini akan hilang dari daftar. Riwayat yang sudah tersimpan tetap ada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.errLine),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    if (n > 0) {
      await AppDb.failPendingFor(s.id, 'Sesi dihapus sebelum terkirim');
    }
    await Store.removeSession(s.id);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sesi dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    final gate = Store.gateToday();
    final name = (gate?.name.isNotEmpty ?? false)
        ? gate!.name
        : Store.prefillName();
    final point = gatePointOf(gate?.point ?? Store.prefillPoint());

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorPanel(message: _error!, onRetry: _retry)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              children: [
                _card(
                  'Petugas hari ini',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Belum diisi' : name,
                                  style: manrope(20, FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${point.value} · ${point.label}',
                                  style: inter(
                                    14,
                                    FontWeight.w500,
                                    color: AppColors.goldInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _editGate,
                            child: const Text('Ganti'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _card(
                  'Sesi absensi',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in _sessions)
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color: AppColors.primary,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: inter(16, FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      s.host,
                                      s.nameFromServer
                                          ? 'terhubung'
                                          : 'belum diverifikasi',
                                      if ((_pendingPer[s.id] ?? 0) > 0)
                                        '${_pendingPer[s.id]} antrean',
                                    ].join(' · '),
                                    style: inter(
                                      14,
                                      FontWeight.w400,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _delete(s),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.muted,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.goldInk,
                          ),
                        ),
                        title: Text(
                          'Tambah sesi (scan QR)',
                          style: inter(16, FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Pakai QR dari panel admin',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                        onTap: _addSession,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _checking
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(
                                  Icons.wifi_tethering_rounded,
                                  color: AppColors.primary,
                                  size: 21,
                                ),
                        ),
                        title: Text(
                          'Cek koneksi server',
                          style: inter(16, FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Buka ulang halaman sesi di server',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                        onTap: _checking ? null : _checkAll,
                      ),
                    ],
                  ),
                ),
                _card(
                  'Umpan balik',
                  Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.volume_up_rounded,
                          size: 21,
                        ),
                        title: Text(
                          'Suara beep',
                          style: inter(16, FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Nada beda untuk tiap hasil',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                        value: Store.soundOn(),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (v) async {
                          await Store.setSoundOn(v);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.vibration_rounded,
                          size: 21,
                        ),
                        title: Text(
                          'Getaran',
                          style: inter(16, FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Hadir: tiga denyut, lainnya: satu denyut',
                          style: inter(
                            14,
                            FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                        value: Store.vibeOn(),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (v) async {
                          await Store.setVibeOn(v);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                _card(
                  'Tentang',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Absensi Sholat', style: inter(16, FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        'Versi 1.0.0 untuk petugas OSIS. Klien pemindai; server sekolah tidak diubah.',
                        style: inter(
                          14,
                          FontWeight.w400,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: inter(
            12,
            FontWeight.w600,
            color: AppColors.muted,
            spacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
