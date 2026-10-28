import 'package:flutter/material.dart';

/// "DJ KING" in a sticker style, with two silver microphones crossed behind it.
class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    // A black outline (shadows in four directions) plus a hard drop shadow.
    final outline = [
      for (final o in const [
        Offset(3, 3),
        Offset(-3, 3),
        Offset(3, -3),
        Offset(-3, -3),
      ])
        Shadow(offset: o, color: Colors.black),
      const Shadow(offset: Offset(0, 8), color: Colors.black),
    ];
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _MicsPainter())),
          Transform.rotate(
            angle: -0.05,
            child: Text(
              'DJ KING',
              style: TextStyle(
                fontFamily: 'Lilita',
                fontSize: 68,
                color: const Color(0xFFFFC93C),
                shadows: outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicsPainter extends CustomPainter {
  const _MicsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * 0.95;
    for (final tilt in const [-0.9, 0.9]) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(tilt);
      _mic(canvas, h);
      canvas.restore();
    }
  }

  /// One microphone, head up, centered on the origin and [h] tall.
  void _mic(Canvas canvas, double h) {
    final silver = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFB8C4D6), Color(0xFFFFFFFF)],
    ).createShader(Rect.fromLTWH(-h * 0.2, 0, h * 0.4, h));
    final fill = Paint()..shader = silver;
    final outline = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    // Handle: tapers toward the bottom.
    final handle = Path()
      ..moveTo(-h * 0.07, -h * 0.12)
      ..lineTo(h * 0.07, -h * 0.12)
      ..lineTo(h * 0.045, h * 0.46)
      ..quadraticBezierTo(0, h * 0.5, -h * 0.045, h * 0.46)
      ..close();
    canvas.drawPath(handle, fill);
    canvas.drawPath(handle, outline);

    // Head with a metal grille.
    final head = Rect.fromCircle(
      center: Offset(0, -h * 0.26),
      radius: h * 0.19,
    );
    canvas.drawOval(head, Paint()..color = const Color(0xFF2B2F3A));
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    final grille = Paint()
      ..color = const Color(0xFFD7DEEA)
      ..strokeWidth = 2.5;
    for (var i = -8; i <= 8; i++) {
      final d = i * h * 0.045;
      canvas.drawLine(
        head.topLeft + Offset(d + h * 0.19, 0),
        head.bottomLeft + Offset(d + h * 0.19 + h * 0.2, 0),
        grille,
      );
      canvas.drawLine(
        head.topLeft + Offset(d + h * 0.19, 0),
        head.bottomLeft + Offset(d + h * 0.19 - h * 0.2, 0),
        grille,
      );
    }
    canvas.restore();
    canvas.drawOval(head, outline);

    // Ring where the head meets the handle.
    final ring = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.08),
        width: h * 0.2,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.02),
    );
    canvas.drawRRect(ring, Paint()..color = const Color(0xFFE63946));
    canvas.drawRRect(ring, outline);
  }

  @override
  bool shouldRepaint(_MicsPainter old) => false;
}
