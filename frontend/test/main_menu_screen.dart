import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/gamescreen.dart';
import 'package:frontend/mainmenuscreen.dart';

void main() {
  Future<void> pumpMainMenu(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
  }

  group("MainMenuScreen Navigation & Dialog Tests", () {
    testWidgets("Start Game button navigates to GameScreen", (
      WidgetTester tester,
    ) async {
      await pumpMainMenu(tester);

      expect(find.byType(MainMenuScreen), findsOneWidget);

      await tester.tap(find.text("Start Game"));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
    });
  });
}
