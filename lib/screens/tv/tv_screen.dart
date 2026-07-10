import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_settings.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/wmc_scaffold.dart';

/// The real Windows Media Center relied on a TV tuner card plugged into the
/// PC. Phones and tablets don't have that hardware, so rather than fake a
/// "live TV" experience with placeholder content, this screen is honest
/// about the limitation and points at where tuner support could plug in
/// later (e.g. a network tuner like HDHomeRun, via its own streaming API).
class TvScreen extends StatelessWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;

    return WmcScaffold(
      title: 'tv',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.live_tv_outlined, size: 48, color: palette.textPrimary),
                const SizedBox(height: 16),
                Text(
                  'No TV tuner detected',
                  style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                Text(
                  'Windows Media Center\'s Live TV and Recorded TV relied on a '
                  'physical TV tuner card in the PC. Android devices don\'t have '
                  'that hardware, so this build doesn\'t simulate live TV with '
                  'placeholder content.\n\n'
                  'A future version could connect to a network tuner (for '
                  'example HDHomeRun) over your home network here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
