import 'package:flutter/material.dart';

import 'aero_background.dart';
import 'wmc_top_bar.dart';
import 'fps_overlay.dart';

/// Every screen in the app (other than full-screen photo/video viewers)
/// wraps its content in this scaffold so the animated background, the top
/// bar and safe-area/gesture-nav handling stay perfectly consistent.
class WmcScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showTopBar;

  const WmcScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showTopBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AeroBackground(
        child: FpsOverlay(
          child: SafeArea(
            child: Column(
              children: [
                if (showTopBar)
                  WmcTopBar(
                    title: title,
                    actions: actions,
                    onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
