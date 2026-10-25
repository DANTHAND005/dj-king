enum GamePhase {
  lobby,
  contestants,
  genre,
  submission,
  songA,
  songB,
  voting,
  result,
  finished,
}

class Room {
  const Room({
    required this.code,
    required this.hostId,
    this.phase = GamePhase.lobby,
    this.roundNumber = 0,
  });

  final String code;
  final String hostId;
  final GamePhase phase;
  final int roundNumber;
}
