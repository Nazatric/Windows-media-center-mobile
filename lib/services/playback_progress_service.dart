import '../core/constants/app_constants.dart';
import 'storage_service.dart';

/// Persists "how far into this video did the user get" so the Video Library
/// can offer a Resume prompt, the way Windows Media Center remembered where
/// you left off in recorded TV.
class PlaybackProgressService {
  PlaybackProgressService(this._storage);

  final StorageService _storage;

  Future<Duration?> getResumePosition(String path) async {
    final map = _storage.getJsonMap(AppConstants.prefResumePositions);
    final millis = map[path];
    if (millis is num && millis > 2000) {
      return Duration(milliseconds: millis.toInt());
    }
    return null;
  }

  Future<void> saveResumePosition(String path, Duration position, Duration? total) async {
    final map = _storage.getJsonMap(AppConstants.prefResumePositions);

    // Don't bother remembering a position if the viewer basically finished
    // the file (within the last 2%), so it doesn't nag to "resume" a video
    // that was already watched to completion.
    final nearEnd = total != null &&
        total.inMilliseconds > 0 &&
        position.inMilliseconds > total.inMilliseconds * 0.98;

    if (nearEnd) {
      map.remove(path);
    } else {
      map[path] = position.inMilliseconds;
    }
    await _storage.setJsonMap(AppConstants.prefResumePositions, map);
  }
}
