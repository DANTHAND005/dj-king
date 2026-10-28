import 'dart:math';

import 'package:flutter/material.dart';

import 'animations.dart';

const _colors = [Color(0xFFE53935), Color(0xFF1E5BD8), Color(0xFF7B2FBF)];

/// A big wheel that spins and lands on [labels][target]. It rests until [target] is set.
/// The host saves the result, so every phone animates to the same one.
class SpinWheel extends StatefulWidget {
  const SpinWheel({super.key, required this.labels, this.target});

  final List<String> labels;
  final int? target;

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final _curve = CurvedAnimation(
    parent: _spin,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.target != null) _spin.forward();
  }

  @override
  void didUpdateWidget(SpinWheel old) {
    super.didUpdateWidget(old);
    if (widget.target != null && widget.target != old.target) {
      _spin.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final step = 2 * pi / widget.labels.length;
    // Five full turns, then stop with the target's slice under the pointer at the top.
    final end = target == null ? 0.0 : 10 * pi - (target + 0.5) * step;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) => Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _WheelPainter(
                          widget.labels,
                          _curve.value * end,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 72,
                    color: Color(0xFFFFC93C),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (target != null && _spin.value == 1)
            Pop(
              key: ValueKey(widget.labels[target]),
              child: Text(
                widget.labels[target],
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            // Keeps the height steady so nothing jumps when the name appears.
            Text(' ', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.labels, this.angle);

  final List<String> labels;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) / 2;
    final step = 2 * pi / labels.length;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    for (var i = 0; i < labels.length; i++) {
      canvas.drawArc(
        rect,
        -pi / 2 + i * step,
        step,
        true,
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.save();
      canvas.rotate(-pi / 2 + (i + 0.5) * step);
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lilita',
            fontSize: labels.length > 16 ? 13 : (labels.length > 8 ? 20 : 28),
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.72);
      text.paint(canvas, Offset(r * 0.93 - text.width, -text.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * 0.08, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.labels != labels;
}
