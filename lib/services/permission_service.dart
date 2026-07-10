import 'package:permission_handler/permission_handler.dart';

import '../models/media_file.dart';

/// Android 13+ replaced the single broad "read external storage" permission
/// with per-media-type permissions. This maps our [MediaKind] to the right
/// one and requests it, falling back to the legacy permission on older OS
/// versions (permission_handler resolves that automatically per-platform).
class PermissionService {
  Future<bool> ensureMediaPermission(MediaKind kind) async {
    final permission = switch (kind) {
      MediaKind.image => Permission.photos,
      MediaKind.video => Permission.videos,
      MediaKind.audio => Permission.audio,
    };

    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }
}
