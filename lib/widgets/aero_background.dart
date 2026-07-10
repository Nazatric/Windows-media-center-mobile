import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_settings.dart';
import '../core/theme/vista_theme.dart';

/// The full-bleed animated backdrop used behind every screen: a deep
/// gradient "sky", a handful of slowly drifting soft-focus bloom particles,
/// and a faint diagonal light streak that sweeps across every so often.
/// Intensity, particle count and speed all come from [ThemeSettings] so the
/// Settings screen's sliders have an immediate, visible effect.
class AeroBackground extends StatefulWidget {
  final Widget child;

  const AeroBackground({super.key, required this.child});

  @override
  State<AeroBackground> createState() => _AeroBackgroundState();
}

class _AeroBackgroundState extends State<AeroBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random(7);
  List<_Particle> _particles = [];
  int _lastParticleCount = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
  }

  void _ensureParticles(int count) {
    if (count == _lastParticleCount) return;
    _lastParticleCount = count;
    _particles = List.generate(count, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        radius: 18 + _rand.nextDouble() * 46,
        speed: 0.015 + _rand.nextDouble() * 0.02,
        phase: _rand.nextDouble(),
        drift: (_rand.nextDouble() - 0.5) * 0.08,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final palette = settings.palette;
    final particleCount = (6 + settings.particleDensity * 26).round();
    _ensureParticles(particleCount);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Vista sky gradient.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.35, -0.8),
              radius: 1.6,
              colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Particles + light streak, all driven by one repeating animation.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _AeroPainter(
                t: _controller.value,
                particles: _particles,
                glow: palette.accentGlow,
                glowIntensity: settings.glowIntensity,
                animationSpeed: settings.animationSpeed,
                reduceBlur: settings.performanceMode,
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x, y, radius, speed, phase, drift;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.drift,
  });
}

class _AeroPainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  final Color glow;
  final double glowIntensity;
  final double animationSpeed;
  final bool reduceBlur;

  _AeroPainter({
    required this.t,
    required this.particles,
    required this.glow,
    required this.glowIntensity,
    required this.animationSpeed,
    required this.reduceBlur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * animationSpeed;

    // Drifting bloom particles ("moving particles" / "lens glow").
    for (final p in particles) {
      final progress = (time * p.speed * 40 + p.phase) % 1.0;
      final dy = (1.2 - progress * 1.4) * size.height;
      final dx = (p.x + sin(progress * 2 * pi) * p.drift) * size.width;
      final fade = sin(progress * pi); // fade in, peak, fade out
      final opacity = (0.14 * glowIntensity * fade).clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;

      final paint = Paint()
        ..color = glow.withOpacity(opacity)
        ..maskFilter = reduceBlur
            ? null
            : MaskFilter.blur(BlurStyle.normal, p.radius * 0.55);
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }

    // Slow diagonal light streak sweep across the whole scene.
    final sweep = (time * 0.05) % 1.0;
    final streakCenter = size.width * (sweep * 2.4 - 0.7);
    final streakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.05 * glowIntensity),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(streakCenter - 220, 0, 440, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), streakPaint);
  }

  @override
  bool shouldRepaint(covariant _AeroPainter oldDelegate) => true;
}
