import 'dart:math';

import 'package:flutter/material.dart';

/// Music notes that slowly drip down the screen like water, forever.
class FallingNotes extends StatefulWidget {
  const FallingNotes({super.key});

  @override
  State<FallingNotes> createState() => _FallingNotesState();
}

class _FallingNotesState extends State<FallingNotes>
    with SingleTickerProviderStateMixin {
  late final _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();
  late final _notes = _makeNotes();

  // Icons rather than ♪ characters: the web font has no glyphs for those.
  static const _icons = [Icons.music_note, Icons.audiotrack, Icons.queue_music];

  static List<_Note> _makeNotes() {
    final random = Random(7);
    return [
      for (var i = 0; i < 16; i++)
        _Note(
          x: random.nextDouble(),
          phase: random.nextDouble(),
          // Whole numbers of falls per loop keep the wrap-around seamless.
          speed: 1 + random.nextInt(2),
          painter: TextPainter(
            text: TextSpan(
              text: String.fromCharCode(_icons[i % 3].codePoint),
              style: TextStyle(
                fontFamily: _icons[i % 3].fontFamily,
                fontSize: 30 + random.nextDouble() * 30,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        ),
    ];
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _NotesPainter(_time, _notes),
      ),
    ),
  );
}

class _Note {
  const _Note({
    required this.x,
    required this.phase,
    required this.speed,
    required this.painter,
  });

  final double x, phase;
  final int speed;
  final TextPainter painter;
}

class _NotesPainter extends CustomPainter {
  _NotesPainter(this.time, this.notes) : super(repaint: time);

  final Animation<double> time;
  final List<_Note> notes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final note in notes) {
      final fall = (time.value * note.speed + note.phase) % 1;
      final h = note.painter.height;
      final y = fall * (size.height + 2 * h) - h;
      final sway = sin(2 * pi * (fall * 3 + note.phase)) * 14;
      note.painter.paint(
        canvas,
        Offset(note.x * (size.width - note.painter.width) + sway, y),
      );
    }
  }

  @override
  bool shouldRepaint(_NotesPainter old) => false;
}
