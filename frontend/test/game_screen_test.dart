import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/gamescreen.dart';

void main() {
  Future<void> pumpGameScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
  }

  group("Gamescreen Counter Tests", () {
    testWidgets("Initial counter is 0", (tester) async {
      await pumpGameScreen(tester);
      expect(find.text("0"), findsOneWidget);
    });

    testWidgets("Counter increments and decrements correctly", (tester) async {
      await pumpGameScreen(tester);

      expect(find.text("0"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text("1"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text("0"), findsOneWidget);
    });

    testWidgets("GameScreen resets counter", (WidgetTester tester) async {
      await pumpGameScreen(tester);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      expect(find.text("5"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Reset"));
      await tester.pumpAndSettle();

      expect(find.text("0"), findsOneWidget);
    });
  });
}
