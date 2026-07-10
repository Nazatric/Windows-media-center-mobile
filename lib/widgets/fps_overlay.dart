import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_settings.dart';

/// When Developer Mode is on (Settings screen), overlays a small live FPS
/// readout in the corner, computed from actual frame timings.
class FpsOverlay extends StatefulWidget {
  final Widget child;
  const FpsOverlay({super.key, required this.child});

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay> {
  double _fps = 60;
  Duration? _lastTimestamp;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (_lastTimestamp != null) {
      final deltaMicros = (timestamp - _lastTimestamp!).inMicroseconds;
      if (deltaMicros > 0 && mounted) {
        final instantFps = 1000000 / deltaMicros;
        setState(() => _fps = (_fps * 0.9) + (instantFps * 0.1));
      }
    }
    _lastTimestamp = timestamp;
  }

  @override
  Widget build(BuildContext context) {
    final developerMode = context.watch<ThemeSettings>().developerMode;
    return Stack(
      children: [
        widget.child,
        if (developerMode)
          Positioned(
            top: 8,
            left: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_fps.toStringAsFixed(0)} FPS',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
