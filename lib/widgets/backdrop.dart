import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'confetti.dart';
import 'falling_notes.dart';

/// True while a game is running. Set by the game screen; makes the yin-yang unravel.
final gameOn = ValueNotifier<bool>(false);

/// Cover picture of the song that is playing, or null. Set by the game screen.
final coverArt = ValueNotifier<String?>(null);

const _red = Color(0xFFE63946);
const _blue = Color(0xFF1D3FBB);

/// Behind the whole app: a slowly turning red and blue yin-yang that unravels into a
/// red-to-blue gradient when a game starts. While a song plays, its blurred cover fades in on top.
class Backdrop extends StatefulWidget {
  const Backdrop({super.key, required this.child});

  final Widget child;

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();
  late final _unravel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
    reverseDuration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    gameOn.addListener(_sync);
    // Nothing is drawn once unraveled, so stop the idle spin instead of rebuilding every frame.
    _unravel.addStatusListener((status) {
      if (status == AnimationStatus.completed) _spin.stop();
    });
    _sync();
  }

  void _sync() {
    if (gameOn.value) {
      _unravel.forward();
    } else {
      if (!_spin.isAnimating) _spin.repeat();
      _unravel.reverse();
    }
  }

  @override
  void dispose() {
    gameOn.removeListener(_sync);
    _spin.dispose();
    _unravel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_red, _blue],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_spin, _unravel]),
          builder: (context, _) {
            final u = Curves.easeInOut.transform(_unravel.value);
            if (u >= 1) return const SizedBox.shrink();
            return RepaintBoundary(
              child: Opacity(
                opacity: 1 - ((u - 0.5) * 2).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + 3 * u * u,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _YinYangPainter(
                      angle: _spin.value * 2 * pi + u * 2 * pi,
                      twist: u * 5 * pi,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const FallingNotes(),
        ValueListenableBuilder<String?>(
          valueListenable: coverArt,
          builder: (context, url, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: url == null
                ? const SizedBox.expand(key: ValueKey('none'))
                : _Cover(key: ValueKey(url), url: url),
          ),
        ),
        widget.child,
        ValueListenableBuilder<int>(
          valueListenable: celebrate,
          builder: (context, count, _) => count == 0
              ? const SizedBox.shrink()
              : Confetti(key: ValueKey(count)),
        ),
      ],
    );
  }
}

/// A yin-yang. With a twist, inner rings turn further than outer ones, which makes it spiral.
class _YinYangPainter extends CustomPainter {
  _YinYangPainter({required this.angle, required this.twist});

  final double angle;
  final double twist;
  static const _rings = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.75;
    canvas.translate(size.width / 2, size.height / 2);
    if (twist == 0) return _symbol(canvas, r, angle);
    // Outer disc first, then smaller discs on top, each turned a little further.
    for (var i = _rings; i >= 1; i--) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(center: Offset.zero, radius: r * i / _rings),
        ),
      );
      _symbol(canvas, r, angle + twist * (1 - i / _rings));
      canvas.restore();
    }
  }

  void _symbol(Canvas canvas, double r, double turn) {
    final red = Paint()..color = _red;
    final blue = Paint()..color = _blue;
    canvas.save();
    canvas.rotate(turn);
    canvas.drawCircle(Offset.zero, r, blue);
    canvas.drawPath(
      Path()
        ..addArc(Rect.fromCircle(center: Offset.zero, radius: r), pi / 2, pi),
      red,
    );
    canvas.drawCircle(Offset(0, -r / 2), r / 2, red);
    canvas.drawCircle(Offset(0, r / 2), r / 2, blue);
    canvas.drawCircle(Offset(0, -r / 2), r / 8, blue);
    canvas.drawCircle(Offset(0, r / 2), r / 8, red);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white24,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_YinYangPainter old) =>
      old.angle != angle || old.twist != twist;
}

class _Cover extends StatelessWidget {
  const _Cover({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 40,
            sigmaY: 40,
            tileMode: TileMode.mirror,
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.black87],
            ),
          ),
        ),
      ],
    );
  }
}
