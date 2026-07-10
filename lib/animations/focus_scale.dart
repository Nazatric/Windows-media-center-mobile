import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import '../services/sound_service.dart';

/// Wraps any child with the "tile comes alive when you touch or focus it"
/// behaviour seen throughout Windows Media Center: a soft scale-up plus a
/// brightness/glow lift. Works with touch, mouse hover (for Android devices
/// with a mouse/trackpad or DeX-style desktop mode) and keyboard/D-pad focus.
class FocusScale extends StatefulWidget {
  final Widget Function(BuildContext context, double t) builder;
  final VoidCallback? onTap;
  final Duration duration;
  final bool playSound;

  const FocusScale({
    super.key,
    required this.builder,
    this.onTap,
    this.duration = const Duration(milliseconds: 180),
    this.playSound = true,
  });

  @override
  State<FocusScale> createState() => _FocusScaleState();
}

class _FocusScaleState extends State<FocusScale> {
  bool _hovering = false;
  bool _pressed = false;
  bool _focused = false;

  double get _t {
    if (_pressed) return 1.0;
    if (_hovering || _focused) return 0.7;
    return 0.0;
  }

  void _handleTap() {
    if (widget.playSound) {
      SoundService.instance.play(SoundService.tap, volume: 0.5);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap == null ? null : _handleTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: 1.0 + (_t * 0.05),
            duration: widget.duration,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: widget.duration,
              curve: Curves.easeOut,
              child: widget.builder(context, _t),
            ),
          ),
        ),
      ),
    );
  }
}
