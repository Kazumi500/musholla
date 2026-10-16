import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/parsing.dart';
import '../services/store.dart';
import '../theme.dart';

Future<void> showAppDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );
}

/// Sheet gerbang harian (nama petugas + titik). Saat `blocking` true (hari baru,
/// belum ada data) sheet tidak bisa ditutup, sama seperti modal di web.
Future<GateState?> showGateSheet(
  BuildContext context, {
  bool blocking = false,
}) async {
  final current = Store.gateToday();
  final nameCtrl = TextEditingController(
    text: current?.name ?? Store.prefillName(),
  );
  var point = current?.point ?? Store.prefillPoint();
  String? error;

  final result = await showModalBottomSheet<GateState>(
    context: context,
    isScrollControlled: true,
    isDismissible: !blocking,
    enableDrag: !blocking,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => PopScope(
        canPop: !blocking,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current == null
                                ? 'Siap bertugas?'
                                : 'Ubah petugas hari ini',
                            style: manrope(20, FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nama dan titik tersimpan sampai besok.',
                            style: inter(
                              14,
                              FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Nama petugas OSIS', style: inter(14, FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'cth: Nabila (OSIS)',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Titik gerbang', style: inter(14, FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: point,
                  items: [
                    for (final p in gatePoints)
                      DropdownMenuItem(
                        value: p.value,
                        child: Text('${p.value} · ${p.label}'),
                      ),
                  ],
                  onChanged: (v) => setSheet(() => point = v ?? point),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.length < 2) {
                      setSheet(
                        () => error = 'Tulis nama petugas, minimal 2 huruf.',
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(
                      GateState(
                        date: Store.todayStr(),
                        name: name,
                        point: point,
                      ),
                    );
                  },
                  child: Text(current == null ? 'Simpan & Mulai' : 'Simpan'),
                ),
                if (!blocking && current != null)
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  nameCtrl.dispose();
  if (result != null) {
    await Store.saveGate(result);
  }
  return result;
}

class SessionPick {
  final ScanSession? session;
  final bool addNew;
  const SessionPick.pick(this.session) : addNew = false;
  const SessionPick.add() : session = null, addNew = true;
}

Future<SessionPick?> showSessionPicker(
  BuildContext context, {
  required List<ScanSession> sessions,
  String? activeId,
}) {
  return showModalBottomSheet<SessionPick>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih sesi', style: manrope(20, FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
              'Scan ini masuk ke sesi yang dipilih.',
              style: inter(14, FontWeight.w400, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            for (final s in sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: Text(s.name, style: inter(16, FontWeight.w600)),
                subtitle: Text(
                  s.host,
                  style: inter(14, FontWeight.w400, color: AppColors.muted),
                ),
                trailing: s.id == activeId
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.secondary,
                      )
                    : null,
                onTap: () => Navigator.of(ctx).pop(SessionPick.pick(s)),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.goldInk),
              ),
              title: Text(
                'Tambah sesi baru',
                style: inter(16, FontWeight.w600),
              ),
              subtitle: Text(
                'Scan QR sesi dari panel admin',
                style: inter(14, FontWeight.w400, color: AppColors.muted),
              ),
              onTap: () => Navigator.of(ctx).pop(const SessionPick.add()),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Input NISN manual: validasi sama dengan web (6 sampai 20 digit angka).
Future<String?> showManualNisnSheet(BuildContext context) async {
  final ctrl = TextEditingController();
  String? error;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        void submit() {
          final v = ctrl.text.trim();
          if (!isNisn(v)) {
            setSheet(
              () => error = 'Format NISN harus 6 sampai 20 digit angka.',
            );
            return;
          }
          Navigator.of(ctx).pop(v);
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Input NISN manual', style: manrope(20, FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  'Ketik angka pada kartu siswa.',
                  style: inter(14, FontWeight.w400, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: InputDecoration(
                    hintText: 'cth: 1234567890',
                    errorText: error,
                  ),
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: submit, child: const Text('Kirim')),
              ],
            ),
          ),
        );
      },
    ),
  );

  ctrl.dispose();
  return result;
}
