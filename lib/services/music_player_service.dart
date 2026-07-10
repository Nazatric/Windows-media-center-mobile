import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/media_file.dart';

/// Wraps a single [AudioPlayer] instance for the whole app so the "Now
/// Playing" state (and the mini transport controls that could later be
/// added to other screens) survive navigation between library screens.
class MusicPlayerService extends ChangeNotifier {
  MusicPlayerService() {
    _player.playingStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.processingStateStream.listen((_) => notifyListeners());
  }

  final AudioPlayer _player = AudioPlayer();
  List<MediaFile> _queue = [];

  AudioPlayer get player => _player;
  List<MediaFile> get queue => List.unmodifiable(_queue);
  MediaFile? get currentTrack {
    final i = _player.currentIndex;
    if (i == null || i < 0 || i >= _queue.length) return null;
    return _queue[i];
  }

  bool get isPlaying => _player.playing;
  bool get hasQueue => _queue.isNotEmpty;

  Future<void> playQueue(List<MediaFile> tracks, {int startIndex = 0}) async {
    _queue = tracks;
    final source = ConcatenatingAudioSource(
      children: tracks.map((t) => AudioSource.uri(Uri.file(t.path))).toList(),
    );
    try {
      await _player.setAudioSource(source, initialIndex: startIndex);
      await _player.play();
    } catch (e) {
      debugPrint('MusicPlayerService: failed to load queue: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() => _player.seekToNext();

  Future<void> previous() => _player.seekToPrevious();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() => _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);

  bool get shuffleEnabled => _player.shuffleModeEnabled;

  LoopMode get loopMode => _player.loopMode;

  Future<void> cycleRepeatMode() {
    final next = switch (_player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    return _player.setLoopMode(next);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
