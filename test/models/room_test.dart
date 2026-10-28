import 'package:dj_king/models/room.dart';
import 'package:dj_king/models/round_result.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> roomData() => {
  'hostId': 'h',
  'hostName': 'Host',
  'hostOnline': true,
  'phase': 'lobby',
  'round': 2,
  'revision': 3,
  'players': {
    'a': {'nickname': 'Ann', 'connected': true},
    'b': {'nickname': 'Bo', 'connected': false},
  },
  'results': {
    'r1': {'winnerId': 'a', 'leftVotes': 2, 'rightVotes': 1, 'reason': 'votes'},
    'r2': {
      'winnerId': 'draw',
      'leftVotes': 1,
      'rightVotes': 1,
      'reason': 'votes',
    },
  },
};

void main() {
  test('parses a lobby room and ignores missing optional data', () {
    final room = Room.fromMap('ABCD', roomData());
    expect(room.phase, GamePhase.lobby);
    expect(room.roundKey, 'r2');
    expect(room.connectedPlayers.map((p) => p.id), ['a']);
    expect(room.songs, isEmpty);
    expect(room.voters, isEmpty);
  });

  test('rooms use all 50 genres unless the host picked 10', () {
    expect(gameGenres.toSet().length, 50);
    expect(Room.fromMap('ABCD', roomData()).genres, gameGenres);
    final picked = Room.fromMap('ABCD', {...roomData(), 'genres': 'Pop|Jazz'});
    expect(picked.genres, ['Pop', 'Jazz']);
  });

  test('scores count wins, draws count for nobody', () {
    final room = Room.fromMap('ABCD', roomData());
    expect(room.scores, {'a': 1, 'b': 0});
    expect(room.leaders, ['a']);
  });

  test('tally ignores contestants and unknown votes, and ties are draws', () {
    final win = RoundResult.tally(
      leftId: 'a',
      rightId: 'b',
      voters: {'v1', 'v2', 'a'},
      votes: {'v1': 'a', 'v2': 'nobody', 'a': 'a'},
    );
    expect((win.winnerId, win.leftVotes, win.rightVotes), ('a', 1, 0));
    final tie = RoundResult.tally(
      leftId: 'a',
      rightId: 'b',
      voters: {'v1', 'v2'},
      votes: {'v1': 'a', 'v2': 'b'},
    );
    expect(tie.winnerId, 'draw');
  });
}
