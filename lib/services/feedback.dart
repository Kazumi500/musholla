import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import 'store.dart';

/// Bunyi dan getar per hasil, mengikuti pola halaman web:
/// hadir = dua nada naik + getar tiga denyut, lainnya satu nada pendek.
class ScanFeedback {
  static final AudioPlayer _player = AudioPlayer();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.9);
    } catch (_) {
      // tanpa audio pun aplikasi tetap jalan
    }
  }

  static Future<void> play(String result) async {
    if (Store.soundOn()) {
      final asset = switch (result) {
        'hadir' => 'sounds/beep_hadir.wav',
        'duplikat' => 'sounds/beep_duplikat.wav',
        'offline' => 'sounds/beep_offline.wav',
        _ => 'sounds/beep_error.wav',
      };
      try {
        await _player.stop();
        await _player.play(AssetSource(asset));
      } catch (_) {}
    }
    if (Store.vibeOn()) {
      try {
        if (await Vibration.hasVibrator()) {
          if (result == 'hadir') {
            await Vibration.vibrate(pattern: [80, 40, 80]);
          } else {
            await Vibration.vibrate(duration: 60);
          }
        }
      } catch (_) {}
    }
  }
}
