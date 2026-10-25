import 'song.dart';

class BattleOrder {
  BattleOrder({required this.left, required this.right});

  final Song left;
  final Song right;
  int _position = 0;

  int get position => _position;
  bool get finished => _position == 2;
  Song? get currentSong => switch (_position) {
    0 => left,
    1 => right,
    _ => null,
  };

  void advance() {
    if (!finished) _position++;
  }
}
