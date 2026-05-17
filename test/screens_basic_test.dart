import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:autoloan/screens/splash_screen.dart';
import 'common/test_utils.dart';

void main() {
  group('Splash Screen', () {
    testWidgets('Splash screen loads', (WidgetTester tester) async {
      await TestUtils.pumpWidget(
        tester,
        const SplashScreen(),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });

  group('Basic Navigation', () {
    testWidgets('App can display widgets', (WidgetTester tester) async {
      await TestUtils.pumpWidget(
        tester,
        const Scaffold(
          body: Center(child: Text('Test')),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
