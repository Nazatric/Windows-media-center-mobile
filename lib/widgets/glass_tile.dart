import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations/focus_scale.dart';
import '../core/theme/theme_settings.dart';

/// The glossy tile used for home-screen categories, album covers, video
/// thumbnails, etc. Includes the characteristic Media Center "reflection"
/// underneath and a glow that intensifies on focus/hover/press.
///
/// [height] is the TOTAL footprint of the widget (glass face + reflection +
/// label text), not just the face. The face/reflection split is computed
/// internally so this can never overflow a fixed-size grid cell no matter
/// what combination of [showReflection] / [subtitle] a caller uses.
class GlassTile extends StatelessWidget {
  final Widget content;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showReflection;

  const GlassTile({
    super.key,
    required this.content,
    required this.label,
    this.subtitle,
    this.onTap,
    this.width = 160,
    this.height = 150,
    this.showReflection = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final palette = settings.palette;

    // Reserve fixed space for the text block(s), then split what's left
    // between the glass face and its reflection.
    final labelBlock = 20.0 + (subtitle != null ? 16.0 : 0.0);
    final spacing = 6.0;
    final remaining = (height - labelBlock - spacing).clamp(40.0, double.infinity);
    final faceHeight = showReflection ? remaining / 1.3 : remaining;
    final reflectionHeight = showReflection ? faceHeight * 0.3 : 0.0;

    return FocusScale(
      onTap: onTap,
      builder: (context, t) {
        final glow = 0.25 + (settings.glowIntensity * 0.6 * t);
        return SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width,
                height: faceHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accentGlow.withOpacity(glow * 0.55),
                      blurRadius: 22 * (0.4 + t),
                      spreadRadius: 1 + t * 2,
                    ),
                  ],
                  border: Border.all(
                    color: palette.glassBorder.withOpacity(0.5 + t * 0.5),
                    width: 1.2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.black.withOpacity(0.25), child: content),
                    // Gloss sweep across the top third of the tile.
                    Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.45,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.30),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showReflection)
                Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()..scale(1.0, -1.0, 1.0),
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0.0)],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: SizedBox(
                      width: width,
                      height: reflectionHeight,
                      child: ClipRect(
                        child: OverflowBox(
                          maxHeight: faceHeight,
                          alignment: Alignment.topCenter,
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: spacing),
              SizedBox(
                height: 18,
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                SizedBox(
                  height: 14,
                  child: Text(
                    subtitle!,
                    style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w300),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
