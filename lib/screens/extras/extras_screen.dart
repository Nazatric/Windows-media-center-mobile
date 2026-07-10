import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_settings.dart';
import '../../widgets/glass_tile.dart';
import '../../widgets/wmc_scaffold.dart';

/// Real Windows Media Center's "extras library" bundled casual games like
/// Chess Titans. We don't ship fake games or fake third-party content here;
/// instead this is a small, honest set of utility tiles that are actually
/// wired up to something real.
class ExtrasScreen extends StatelessWidget {
  const ExtrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;

    return WmcScaffold(
      title: 'extras library',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 28,
          crossAxisSpacing: 20,
          childAspectRatio: 1.05,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => GlassTile(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                label: 'about',
                showReflection: false,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _AboutDialog(),
                ),
                content: Center(child: Icon(Icons.info_outline, size: 40, color: palette.textPrimary)),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => GlassTile(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                label: 'credits',
                showReflection: false,
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0F1E2E),
                    title: const Text('Credits', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'An unofficial, fan-made recreation of the Windows Media '
                      'Center interface, built with Flutter. Not affiliated '
                      'with or endorsed by Microsoft.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                content: Center(child: Icon(Icons.favorite_border, size: 40, color: palette.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1E2E),
      title: const Text('Windows Media Center', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Version 1.0.0\n\n'
        'An unofficial Flutter recreation of the Windows Vista / '
        'Windows 7 era Windows Media Center interface.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
