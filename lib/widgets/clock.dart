import 'dart:async';

import 'package:flutter/material.dart';

import '../services/game_service.dart';

/// Big seconds-left display for a shared server deadline.
class Clock extends StatefulWidget {
  const Clock({
    super.key,
    required this.game,
    required this.deadline,
    required this.label,
  });

  final GameService game;
  final int? deadline;
  final String label;

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (((widget.deadline ?? 0) - widget.game.now) / 1000)
        .ceil()
        .clamp(0, 999);
    final theme = Theme.of(context).textTheme;
    return Semantics(
      label: '${widget.label} $seconds',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(widget.label, style: theme.titleMedium),
          // The last five seconds turn yellow and pulse once per second.
          TweenAnimationBuilder<double>(
            key: ValueKey(seconds <= 5 ? seconds : -1),
            tween: Tween(begin: seconds <= 5 ? 1.4 : 1, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$seconds',
              style: theme.displayLarge?.copyWith(
                color: seconds <= 5 ? const Color(0xFFFFC93C) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
