import 'dart:io';

import '../core/constants/app_constants.dart';
import '../models/media_file.dart';

/// Windows Media Center pointed at a "Pictures Library" / "Music Library" /
/// "Videos Library" folder rather than scanning the whole device. We follow
/// the same philosophy: the user explicitly chooses a folder (via the
/// system's Storage Access Framework file/folder picker) and we index just
/// that tree, instead of demanding broad "read all storage" permission.
class MediaScannerService {
  Future<List<MediaFile>> scan(String rootPath, MediaKind kind) async {
    final dir = Directory(rootPath);
    if (!await dir.exists()) return [];

    final extensions = switch (kind) {
      MediaKind.image => AppConstants.imageExtensions,
      MediaKind.video => AppConstants.videoExtensions,
      MediaKind.audio => AppConstants.audioExtensions,
    };

    final results = <MediaFile>[];

    try {
      final stream = dir.list(recursive: true, followLinks: false);
      await for (final entity in stream) {
        if (results.length >= AppConstants.maxFilesPerScan) break;
        if (entity is! File) continue;

        final ext = entity.path.split('.').last.toLowerCase();
        if (!extensions.contains(ext)) continue;

        final media = MediaFile.fromEntity(entity, kind);
        if (media != null) results.add(media);
      }
    } catch (_) {
      // Permission revoked mid-scan, folder deleted, etc. Return whatever
      // was gathered so far rather than crashing the library screen.
    }

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results;
  }

  /// Groups a flat file list into "albums" keyed by immediate parent folder,
  /// mirroring how Windows Media Center grouped pictures/music by folder.
  Map<String, List<MediaFile>> groupByFolder(List<MediaFile> files) {
    final groups = <String, List<MediaFile>>{};
    for (final f in files) {
      groups.putIfAbsent(f.folderName, () => []).add(f);
    }
    return groups;
  }
}
