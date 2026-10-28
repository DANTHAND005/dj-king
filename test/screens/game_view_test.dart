import 'package:dj_king/models/room.dart';
import 'package:dj_king/screens/game_view.dart';
import 'package:dj_king/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> song(String title) => {
  'videoId': 'dQw4w9WgXcQ',
  'title': title,
  'channel': 'c',
  'thumbnailUrl': 'https://i.ytimg.com/x.jpg',
};

Room room(String phase, [Map<String, dynamic> extra = const {}]) =>
    Room.fromMap('ABCD', {
      'hostId': 'h',
      'hostName': 'Host',
      'hostOnline': true,
      'phase': phase,
      'round': 1,
      'revision': 1,
      'leftId': 'a',
      'rightId': 'b',
      'genre': 'Jazz',
      'players': {
        'a': {'nickname': 'Ann', 'connected': true},
        'b': {'nickname': 'Bo', 'connected': true},
        'v': {'nickname': 'Vic', 'connected': true},
      },
      'voters': {'v': true},
      'songs': {'a': song('Song A'), 'b': song('Song B')},
      'deadline': DateTime.now().millisecondsSinceEpoch + 20000,
      ...extra,
    });

Future<void> show(WidgetTester tester, Room r, String uid) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: GameView(game: GameService(), room: r, uid: uid),
      ),
    ),
  ),
);

void main() {
  testWidgets('a voter sees both songs to vote on, a contestant does not', (
    tester,
  ) async {
    await show(tester, room('voting'), 'v');
    expect(find.text('Ann\nSong A'), findsOneWidget);
    expect(find.text('Bo\nSong B'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await show(tester, room('voting'), 'a');
    expect(find.text('Ann\nSong A'), findsNothing);
    expect(find.text('The voters are choosing.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('result shows the winner and only the host can continue', (
    tester,
  ) async {
    final results = {
      'r1': {
        'winnerId': 'a',
        'leftVotes': 1,
        'rightVotes': 0,
        'reason': 'votes',
      },
    };
    await show(tester, room('result', {'results': results}), 'v');
    expect(find.text('Ann wins the round'), findsOneWidget);
    expect(find.text('Next round'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await show(tester, room('result', {'results': results}), 'h');
    expect(find.text('Next round'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('final screen announces a tie', (tester) async {
    final results = {
      'r1': {
        'winnerId': 'a',
        'leftVotes': 1,
        'rightVotes': 0,
        'reason': 'votes',
      },
      'r2': {
        'winnerId': 'b',
        'leftVotes': 0,
        'rightVotes': 1,
        'reason': 'votes',
      },
    };
    await show(tester, room('finished', {'results': results, 'round': 5}), 'v');
    expect(find.text('Tie: Ann, Bo'), findsOneWidget);
  });

  testWidgets('host moves from contestants to genre', (tester) async {
    await show(tester, room('contestants'), 'h');
    expect(find.text('Pick the genre'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after the final, only the host can start a new game', (
    tester,
  ) async {
    await show(tester, room('finished', {'round': 5}), 'v');
    expect(find.text('Play again with new contestants'), findsNothing);
    await show(tester, room('finished', {'round': 5}), 'h');
    expect(find.text('Play again with new contestants'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
