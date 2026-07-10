import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_settings.dart';
import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/music_player_service.dart';
import '../../services/permission_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/wmc_scaffold.dart';
import 'now_playing_screen.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
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
    final saved = storage.getString(AppConstants.prefMusicFolder);
    if (saved != null) {
      setState(() => _folder = saved);
      await _scan(saved);
    }
  }

  Future<void> _chooseFolder() async {
    final granted = await _permissions.ensureMediaPermission(MediaKind.audio);
    if (!granted) {
      SoundService.instance.play(SoundService.error, volume: 0.5);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Music access was denied.')));
      return;
    }
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a music folder');
    if (path == null) return;

    final storage = await StorageService.getInstance();
    await storage.setString(AppConstants.prefMusicFolder, path);
    setState(() => _folder = path);
    await _scan(path);
  }

  Future<void> _scan(String path) async {
    setState(() => _loading = true);
    final files = await _scanner.scan(path, MediaKind.audio);
    final albums = _scanner.groupByFolder(files);
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  void _playAlbum(List<MediaFile> tracks, {int startIndex = 0}) {
    final player = context.read<MusicPlayerService>();
    player.playQueue(tracks, startIndex: startIndex);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return WmcScaffold(
      title: 'music library',
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
                Icon(Icons.library_music_outlined, size: 48, color: palette.textPrimary),
                const SizedBox(height: 16),
                Text(
                  'Choose a folder on your device to build your music library.',
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
                  child: const Text('choose music folder'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_albums.isEmpty) {
      return Center(
        child: Text('No audio files found in that folder.',
            style: TextStyle(color: palette.textPrimary)),
      );
    }

    final albumNames = _albums.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: albumNames.length,
      itemBuilder: (context, index) {
        final name = albumNames[index];
        final tracks = _albums[name]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpansionTile(
              iconColor: palette.textPrimary,
              collapsedIconColor: palette.textSecondary,
              title: Text(name, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w400)),
              subtitle: Text('${tracks.length} track${tracks.length == 1 ? '' : 's'}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12)),
              trailing: IconButton(
                icon: Icon(Icons.play_circle_outline, color: palette.accentGlow),
                onPressed: () => _playAlbum(tracks),
              ),
              children: [
                for (int i = 0; i < tracks.length; i++)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.music_note, color: palette.textSecondary, size: 18),
                    title: Text(
                      tracks[i].name,
                      style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w300, fontSize: 13),
                    ),
                    onTap: () => _playAlbum(tracks, startIndex: i),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
