import 'package:dj_king/widgets/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the song cover only while one is set', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Backdrop(child: Text('hello'))),
    );
    expect(find.byType(Image), findsNothing);

    coverArt.value = 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg';
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);

    coverArt.value = null;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('unravels when a game starts and winds back when it ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Backdrop(child: Text('hello'))),
    );
    gameOn.value = true;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
    gameOn.value = false;
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('hello'), findsOneWidget);
  });
}
