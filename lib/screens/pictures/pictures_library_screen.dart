import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_settings.dart';
import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/permission_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_tile.dart';
import '../../widgets/wmc_scaffold.dart';
import 'photo_viewer_screen.dart';

class PicturesLibraryScreen extends StatefulWidget {
  const PicturesLibraryScreen({super.key});

  @override
  State<PicturesLibraryScreen> createState() => _PicturesLibraryScreenState();
}

class _PicturesLibraryScreenState extends State<PicturesLibraryScreen> {
  final _scanner = MediaScannerService();
  final _permissions = PermissionService();

  bool _loading = false;
  String? _folder;
  Map<String, List<MediaFile>> _albums = {};

  @override
  void initState() {
    super.initState();
    _restoreFolder();
  }

  Future<void> _restoreFolder() async {
    final storage = await StorageService.getInstance();
    final saved = storage.getString(AppConstants.prefPicturesFolder);
    if (saved != null) {
      setState(() => _folder = saved);
      await _scan(saved);
    }
  }

  Future<void> _chooseFolder() async {
    final granted = await _permissions.ensureMediaPermission(MediaKind.image);
    if (!granted) {
      SoundService.instance.play(SoundService.error, volume: 0.5);
      if (mounted) {
        _showMessage('Photo access was denied, so the pictures library can\'t be scanned.');
      }
      return;
    }

    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a pictures folder');
    if (path == null) return;

    final storage = await StorageService.getInstance();
    await storage.setString(AppConstants.prefPicturesFolder, path);
    setState(() => _folder = path);
    await _scan(path);
  }

  Future<void> _scan(String path) async {
    setState(() => _loading = true);
    final files = await _scanner.scan(path, MediaKind.image);
    final albums = _scanner.groupByFolder(files);
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return WmcScaffold(
      title: 'pictures library',
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open, color: Colors.white70),
          tooltip: 'Choose folder',
          onPressed: _chooseFolder,
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_folder == null) {
      return _EmptyState(
        icon: Icons.photo_library_outlined,
        message: 'Choose a folder on your device to build your pictures library.',
        buttonLabel: 'choose pictures folder',
        onPressed: _chooseFolder,
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_albums.isEmpty) {
      return _EmptyState(
        icon: Icons.image_not_supported_outlined,
        message: 'No pictures were found in that folder.',
        buttonLabel: 'choose a different folder',
        onPressed: _chooseFolder,
      );
    }

    final albumNames = _albums.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        itemCount: albumNames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 32,
          crossAxisSpacing: 20,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final name = albumNames[index];
          final photos = _albums[name]!;
          return LayoutBuilder(
            builder: (context, constraints) {
              return GlassTile(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                label: name,
                subtitle: '${photos.length} picture${photos.length == 1 ? '' : 's'}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => _AlbumScreen(name: name, photos: photos)),
                ),
                content: Image.file(
                  photos.first.file,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white38),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlbumScreen extends StatelessWidget {
  final String name;
  final List<MediaFile> photos;

  const _AlbumScreen({required this.name, required this.photos});

  @override
  Widget build(BuildContext context) {
    return WmcScaffold(
      title: name,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: 0, slideshow: true),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 10),
                    Text('play slide show', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: index),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        photo.file,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Colors.black26, child: Icon(Icons.broken_image_outlined, color: Colors.white38)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanel(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: palette.textPrimary.withOpacity(0.85)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w300, fontSize: 15),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  side: BorderSide(color: palette.glassBorder),
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
