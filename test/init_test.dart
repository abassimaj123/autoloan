import 'package:flutter_test/flutter_test.dart';
import 'package:autoloan/main.dart';

void main() {
  group('AutoLoan App Initialization', () {
    testWidgets('App launches without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const AutoLoanApp());
      await tester.pumpAndSettle();

      expect(find.byType(AutoLoanApp), findsOneWidget);
    });
  });
}
