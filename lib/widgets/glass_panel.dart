import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_settings.dart';
import '../core/theme/vista_theme.dart';

/// A single reusable "pane of glass": backdrop blur, a translucent tint,
/// a thin bright border, and a soft highlight along the top edge to fake a
/// glossy reflection. Every panel, tile and dialog in the app is built out
/// of this one widget so the whole UI stays visually consistent.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool showTopHighlight;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.showTopHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final palette = settings.palette;
    final sigma = 4 + settings.blurAmount * 18;
    final tintAlpha = (0.25 + settings.glassIntensity * 0.35).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.10 * tintAlpha + 0.02),
                palette.glassTint.withOpacity(tintAlpha * 0.5),
                Colors.black.withOpacity(0.20 * tintAlpha + 0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: palette.glassBorder.withOpacity(0.7), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (showTopHighlight)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
