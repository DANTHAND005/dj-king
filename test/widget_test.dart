import 'package:dj_king/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the starter launches without errors', (tester) async {
    await tester.pumpWidget(const DjKingApp());

    expect(find.text('DJ King'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
