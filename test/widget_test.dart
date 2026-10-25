import 'dart:async';

import 'package:dj_king/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading until sign-in finishes', (tester) async {
    final signIn = Completer<String>();
    await tester.pumpWidget(DjKingApp(signIn: () => signIn.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Choose a song'), findsNothing);

    signIn.complete('player-one');
    await tester.pumpAndSettle();
    expect(find.text('player-one'), findsOneWidget);
    expect(find.text('Choose a song'), findsOneWidget);
  });

  testWidgets('failed sign-in can be retried', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      DjKingApp(
        signIn: () async {
          if (attempts++ == 0) throw StateError('Offline');
          return 'player-two';
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('player-two'), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
