import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_settings.dart';
import '../../core/theme/vista_theme.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/wmc_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final palette = settings.palette;

    return WmcScaffold(
      title: 'settings',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          _SectionPanel(
            title: 'theme',
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: VistaVariant.values.map((v) {
                  final p = VistaPalette.all[v]!;
                  final selected = settings.variant == v;
                  return GestureDetector(
                    onTap: () => settings.setVariant(v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [p.skyTop, p.skyBottom]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white24,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(p.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          _SectionPanel(
            title: 'glass & animation',
            children: [
              _SettingSlider(
                label: 'Glass intensity',
                value: settings.glassIntensity,
                onChanged: settings.setGlassIntensity,
              ),
              _SettingSlider(
                label: 'Blur amount',
                value: settings.blurAmount,
                onChanged: settings.setBlurAmount,
              ),
              _SettingSlider(
                label: 'Glow intensity',
                value: settings.glowIntensity,
                onChanged: settings.setGlowIntensity,
              ),
              _SettingSlider(
                label: 'Particle density',
                value: settings.particleDensity,
                onChanged: settings.setParticleDensity,
              ),
              _SettingSlider(
                label: 'Animation speed',
                value: (settings.animationSpeed - 0.25) / (2.0 - 0.25),
                onChanged: (v) => settings.setAnimationSpeed(0.25 + v * (2.0 - 0.25)),
              ),
            ],
          ),
          _SectionPanel(
            title: 'performance',
            children: [
              SwitchListTile(
                value: settings.soundEffectsEnabled,
                onChanged: settings.setSoundEffectsEnabled,
                activeColor: palette.accentGlow,
                title: Text('Sound effects', style: TextStyle(color: palette.textPrimary)),
                subtitle: Text('Startup chime, navigation and tap sounds',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12)),
              ),
              SwitchListTile(
                value: settings.performanceMode,
                onChanged: settings.setPerformanceMode,
                activeColor: palette.accentGlow,
                title: Text('Performance mode', style: TextStyle(color: palette.textPrimary)),
                subtitle: Text('Reduces blur & particle count for low-end devices',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12)),
              ),
              SwitchListTile(
                value: settings.developerMode,
                onChanged: settings.setDeveloperMode,
                activeColor: palette.accentGlow,
                title: Text('Developer mode', style: TextStyle(color: palette.textPrimary)),
                subtitle: Text('Shows a live FPS counter overlay',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12)),
              ),
              ListTile(
                title: Text('Clear cache', style: TextStyle(color: palette.textPrimary)),
                subtitle: Text('Clears the in-memory image cache and remembered playback positions',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                trailing: Icon(Icons.cleaning_services_outlined, color: palette.textSecondary),
                onTap: () async {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  final storage = await StorageService.getInstance();
                  await storage.remove(AppConstants.prefResumePositions);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Cache cleared.')));
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: TextButton(
                onPressed: settings.resetToDefaults,
                child: const Text('Reset to defaults'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: palette.textSecondary, fontSize: 13, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SettingSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w300)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: palette.accentGlow,
            inactiveTrackColor: Colors.white24,
            thumbColor: palette.accentGlow,
            trackHeight: 2,
          ),
          child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged),
        ),
      ],
    );
  }
}
