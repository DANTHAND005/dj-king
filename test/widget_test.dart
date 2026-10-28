import 'dart:async';

import 'package:dj_king/app.dart';
import 'package:dj_king/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The background spins forever, so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows loading until sign-in finishes, then the front page', (
    tester,
  ) async {
    final signIn = Completer<String>();
    await tester.pumpWidget(
      DjKingApp(signIn: () => signIn.future, game: GameService()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Join'), findsNothing);

    signIn.complete('player-one');
    await settle(tester);
    expect(find.text('Join'), findsOneWidget);
    expect(find.text('Host a game'), findsOneWidget);
    expect(find.text('Choose a song'), findsNothing);
  });

  testWidgets('failed sign-in can be retried', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      DjKingApp(
        game: GameService(),
        signIn: () async {
          if (attempts++ == 0) throw StateError('Offline');
          return 'player-two';
        },
      ),
    );
    await settle(tester);

    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await settle(tester);

    expect(find.text('Join'), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('joining without a nickname shows a message and stays put', (
    tester,
  ) async {
    await tester.pumpWidget(
      DjKingApp(signIn: () async => 'p', game: GameService()),
    );
    await settle(tester);
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(
      find.text('Enter a nickname of 1 to 20 characters.'),
      findsOneWidget,
    );
  });
}
