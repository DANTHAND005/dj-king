import 'dart:async';

import 'package:flutter/material.dart';

class BattleCountdown extends StatefulWidget {
  const BattleCountdown({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BattleCountdown> createState() => _BattleCountdownState();
}

class _BattleCountdownState extends State<BattleCountdown> {
  late final Timer _timer;
  int _seconds = 5;

  @override
  void initState() {
    super.initState();
    // shortcut: local preview timer; use a shared server deadline for multiplayer.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 1) {
        timer.cancel();
        widget.onFinished();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        'Battle starts in $_seconds',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
