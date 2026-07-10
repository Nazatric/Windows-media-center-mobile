import 'package:flutter/widgets.dart';

/// Windows Media Center never hard-cuts between screens; every navigation
/// fades and gently scales the incoming page. This route recreates that
/// feel and is used for every push in the app instead of the platform
/// default slide transition.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required WidgetBuilder builder, required Duration duration})
      : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}
