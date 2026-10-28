import 'dart:math';

import 'package:flutter/material.dart';

/// Bump to throw confetti over the whole app. Set by the game screen on a win.
final celebrate = ValueNotifier<int>(0);

const _colors = [
  Color(0xFFE63946),
  Color(0xFF1D3FBB),
  Color(0xFFFFC93C),
  Colors.white,
];

/// One burst of confetti that falls once and ends.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final _time = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..forward();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(size: Size.infinite, painter: _Painter(_time)),
  );
}

class _Painter extends CustomPainter {
  _Painter(this.time) : super(repaint: time);

  final Animation<double> time;
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(3); // same seed: same pieces on every phone
    for (var i = 0; i < 80; i++) {
      final x = random.nextDouble(), delay = random.nextDouble() * 0.3;
      final speed = 0.6 + random.nextDouble() * 0.4;
      final spin = random.nextDouble() * 10, sway = random.nextDouble() * 40;
      final t = ((time.value - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t == 0 || t == 1) continue;
      canvas.save();
      canvas.translate(
        x * size.width + sin(t * 8 + spin) * sway,
        -20 + t * speed * (size.height + 60),
      );
      canvas.rotate(t * spin * 3);
      canvas.drawRect(
        const Rect.fromLTWH(-6, -3, 12, 6),
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Painter old) => false;
}
