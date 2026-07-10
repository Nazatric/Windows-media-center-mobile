import 'dart:io';

import 'package:path/path.dart' as p;

enum MediaKind { image, video, audio }

class MediaFile {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modified;
  final MediaKind kind;

  /// The immediate parent folder name, used to group files into
  /// "albums" for Pictures and Music.
  final String folderName;

  MediaFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modified,
    required this.kind,
  }) : folderName = p.basename(p.dirname(path));

  static MediaFile? fromEntity(FileSystemEntity entity, MediaKind kind) {
    if (entity is! File) return null;
    try {
      final stat = entity.statSync();
      final name = p.basename(entity.path);
      final ext = p.extension(entity.path).replaceFirst('.', '').toLowerCase();
      return MediaFile(
        path: entity.path,
        name: name,
        extension: ext,
        sizeBytes: stat.size,
        modified: stat.modified,
        kind: kind,
      );
    } catch (_) {
      return null;
    }
  }

  File get file => File(path);
}
