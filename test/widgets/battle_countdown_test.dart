import 'package:dj_king/widgets/battle_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('finishes once after five seconds', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: BattleCountdown(onFinished: () => completed++)),
    );
    expect(find.text('Battle starts in 5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Battle starts in 1'), findsOneWidget);
    expect(completed, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(completed, 1);
  });

  testWidgets('leaving the countdown cancels the transition', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: BattleCountdown(onFinished: () => completed++)),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });
}
