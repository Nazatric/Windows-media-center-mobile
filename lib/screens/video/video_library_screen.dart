import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_settings.dart';
import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/permission_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_tile.dart';
import '../../widgets/wmc_scaffold.dart';
import 'video_player_screen.dart';

/// Generic "browse a folder of video files" screen. The Videos category and
/// the Movies category are, functionally, the exact same feature pointed at
/// a different remembered folder — so this one screen serves both, the way
/// a lot of the Media Center UI reused its list/details chrome across
/// categories.
class VideoLibraryScreen extends StatefulWidget {
  final String title;
  final String folderPrefKey;

  const VideoLibraryScreen({
    super.key,
    this.title = 'video library',
    this.folderPrefKey = 'folder.videos',
  });

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  final _scanner = MediaScannerService();
  final _permissions = PermissionService();

  bool _loading = false;
  String? _folder;
  List<MediaFile> _videos = [];

  @override
  void initState() {
    super.initState();
    _restoreFolder();
  }

  Future<void> _restoreFolder() async {
    final storage = await StorageService.getInstance();
    final saved = storage.getString(widget.folderPrefKey);
    if (saved != null) {
      setState(() => _folder = saved);
      await _scan(saved);
    }
  }

  Future<void> _chooseFolder() async {
    final granted = await _permissions.ensureMediaPermission(MediaKind.video);
    if (!granted) {
      SoundService.instance.play(SoundService.error, volume: 0.5);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Video access was denied.')));
      }
      return;
    }
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a ${widget.title} folder');
    if (path == null) return;

    final storage = await StorageService.getInstance();
    await storage.setString(widget.folderPrefKey, path);
    setState(() => _folder = path);
    await _scan(path);
  }

  Future<void> _scan(String path) async {
    setState(() => _loading = true);
    final files = await _scanner.scan(path, MediaKind.video);
    if (!mounted) return;
    setState(() {
      _videos = files;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WmcScaffold(
      title: widget.title,
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open, color: Colors.white70),
          tooltip: 'Choose folder',
          onPressed: _chooseFolder,
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final palette = context.watch<ThemeSettings>().palette;

    if (_folder == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_filter_outlined, size: 48, color: palette.textPrimary),
                const SizedBox(height: 16),
                Text(
                  'Choose a folder on your device to build your ${widget.title}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _chooseFolder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textPrimary,
                    side: BorderSide(color: palette.glassBorder),
                  ),
                  child: const Text('choose folder'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_videos.isEmpty) {
      return Center(
        child: Text('No video files found in that folder.', style: TextStyle(color: palette.textPrimary)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        itemCount: _videos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 32,
          crossAxisSpacing: 20,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final video = _videos[index];
          return LayoutBuilder(
            builder: (context, constraints) {
              return GlassTile(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                label: video.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(video: video, playlist: _videos, index: index),
                  ),
                ),
                content: Center(
                  child: Icon(Icons.play_circle_fill, size: 40, color: palette.textPrimary.withOpacity(0.85)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
