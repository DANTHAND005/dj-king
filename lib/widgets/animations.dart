import 'package:flutter/material.dart';

/// For AnimatedSwitcher: the new screen slides in from the right while fading in.
Widget slideFade(Widget child, Animation<double> animation) => FadeTransition(
  opacity: animation,
  child: SlideTransition(
    position: Tween(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  ),
);

/// Bounces its child in when it first appears.
class Pop extends StatelessWidget {
  const Pop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.5, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.elasticOut,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: child,
  );
}
