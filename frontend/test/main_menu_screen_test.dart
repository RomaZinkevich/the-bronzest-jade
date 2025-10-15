import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_who/gamescreen.dart';
import 'package:guess_who/mainmenuscreen.dart';
import 'package:guess_who/theme/app_theme.dart';

void main() {
  Future<void> pumpMainMenuScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainMenuScreen()),
    );
  }

  group("Navigation Tests", () {
    testWidgets("navigate to GameScreen", (WidgetTester tester) async {
      await pumpMainMenuScreen(tester);

      await tester.tap(find.text('Play local'));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Game Screen'), findsOneWidget);
    });

    testWidgets("navigate back to main menu", (WidgetTester tester) async {
      await pumpMainMenuScreen(tester);

      await tester.tap(find.text("Play local"));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(MainMenuScreen), findsOneWidget);
    });
  });

  group("Room Code Input Tests", () {
    testWidgets("text field accepts input", (WidgetTester tester) async {
      await pumpMainMenuScreen(tester);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'ROOM123');
      await tester.pump();

      expect(find.text("ROOM123"), findsOneWidget);
    });

    testWidgets('empty room throws error', (WidgetTester tester) async {
      await pumpMainMenuScreen(tester);

      final submitButton = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                "assets/icons/join_submit.png",
      );

      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text("Please enter a room code"), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
