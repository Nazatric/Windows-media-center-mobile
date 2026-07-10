import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_settings.dart';

class WmcTopBar extends StatefulWidget {
  final String title;
  final VoidCallback? onHome;
  final List<Widget> actions;

  const WmcTopBar({super.key, required this.title, this.onHome, this.actions = const []});

  @override
  State<WmcTopBar> createState() => _WmcTopBarState();
}

class _WmcTopBarState extends State<WmcTopBar> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 22,
                fontWeight: FontWeight.w200,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...widget.actions,
          const SizedBox(width: 16),
          Text(
            _formatTime(_now),
            style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w300),
          ),
          const SizedBox(width: 12),
          _StartOrb(onTap: widget.onHome),
        ],
      ),
    );
  }
}

/// The little glowing green/blue "start orb" in the corner, evocative of the
/// Windows flag button that always returned Media Center to its Start strip.
class _StartOrb extends StatelessWidget {
  final VoidCallback? onTap;
  const _StartOrb({this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeSettings>().palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [palette.accentGlow, palette.skyMid],
          ),
          boxShadow: [
            BoxShadow(color: palette.accentGlow.withOpacity(0.6), blurRadius: 10, spreadRadius: 1),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
      ),
    );
  }
}
