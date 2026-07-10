import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../animations/fade_scale_route.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_settings.dart';
import '../../services/sound_service.dart';
import '../../widgets/aero_background.dart';
import '../../widgets/glass_tile.dart';
import '../../widgets/wmc_top_bar.dart';
import '../extras/extras_screen.dart';
import '../movies/movies_screen.dart';
import '../music/music_library_screen.dart';
import '../pictures/pictures_library_screen.dart';
import '../settings/settings_screen.dart';
import '../tv/tv_screen.dart';
import '../video/video_library_screen.dart';

class _Category {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _Category(this.label, this.icon, this.builder);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<_Category> _categories = [
    _Category('pictures', Icons.photo_library_outlined, (_) => const PicturesLibraryScreen()),
    _Category('videos', Icons.movie_filter_outlined, (_) => const VideoLibraryScreen()),
    _Category('music', Icons.library_music_outlined, (_) => const MusicLibraryScreen()),
    _Category('movies', Icons.theaters_outlined, (_) => const MoviesScreen()),
    _Category('tv', Icons.live_tv_outlined, (_) => const TvScreen()),
    _Category('extras', Icons.apps_outlined, (_) => const ExtrasScreen()),
    _Category('settings', Icons.settings_outlined, (_) => const SettingsScreen()),
  ];

  void _open(BuildContext context, _Category c) {
    SoundService.instance.play(SoundService.navigate, volume: 0.55);
    final speed = context.read<ThemeSettings>().animationSpeed;
    final duration = Duration(
      milliseconds: (AppConstants.pageTransition.inMilliseconds / speed).round(),
    );
    Navigator.of(context).push(FadeScaleRoute(builder: c.builder, duration: duration));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AeroBackground(
        child: SafeArea(
          child: Column(
            children: [
              WmcTopBar(title: 'windows media center'),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    // Keep the authentic Media Center proportions instead of
                    // stretching the tile grid across ultra-tall phones.
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: GridView.builder(
                        itemCount: _categories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 28,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, index) {
                          final c = _categories[index];
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return GlassTile(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                label: c.label,
                                showReflection: false,
                                onTap: () => _open(context, c),
                                content: Center(
                                  child: Icon(
                                    c.icon,
                                    size: 46,
                                    color: palette.textPrimary.withOpacity(0.9),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
