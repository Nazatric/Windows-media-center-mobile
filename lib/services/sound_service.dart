import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the short UI sound effects (tile taps, navigation, notifications,
/// the startup chime) bundled under assets/sounds/. Deliberately separate
/// from [MusicPlayerService]: these are one-shot, fire-and-forget clips, not
/// a queue/playlist, and each call gets its own short-lived [AudioPlayer]
/// so overlapping taps don't cut each other off.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _muted = false;
  set muted(bool value) => _muted = value;
  bool get muted => _muted;

  static const String startup = 'assets/sounds/Windows Logon Sound.wav';
  static const String tap = 'assets/sounds/Windows Menu Command.wav';
  static const String navigate = 'assets/sounds/Windows Navigation Start.wav';
  static const String error = 'assets/sounds/Windows Error.wav';
  static const String notify = 'assets/sounds/Windows Notify.wav';
  static const String recycle = 'assets/sounds/Windows Recycle.wav';

  Future<void> play(String assetPath, {double volume = 0.7}) async {
    if (_muted) return;
    final player = AudioPlayer();
    try {
      await player.setAsset(assetPath);
      await player.setVolume(volume);
      await player.play();
      // Fire-and-forget: dispose once playback finishes so we don't leak
      // players, without making every call site await the full clip.
      unawaited(player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .then((_) => player.dispose())
          .catchError((_) => player.dispose()));
    } catch (e) {
      debugPrint('SoundService: failed to play $assetPath: $e');
      await player.dispose();
    }
  }
}
