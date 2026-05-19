import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calcwise_core/calcwise_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal host — no Firebase, no AdMob, no IAP.
Widget _host(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        extensions: [CalcwiseTheme.light(primary: const Color(0xFF0D47A1))],
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ResultTile', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(_host(
        const ResultTile(label: 'Monthly Payment', value: r'$349'),
      ));
      await tester.pump();
      expect(find.text('Monthly Payment'), findsOneWidget);
      expect(find.text(r'$349'), findsOneWidget);
    });

    testWidgets('highlighted tile renders without error', (tester) async {
      await tester.pumpWidget(_host(
        const ResultTile(
          label: 'Total Cost of Loan',
          value: r'$21,000',
          isHighlight: true,
        ),
      ));
      await tester.pump();
      expect(find.text('Total Cost of Loan'), findsOneWidget);
    });

    testWidgets('renders interest and principal tiles', (tester) async {
      await tester.pumpWidget(_host(
        const Column(
          children: [
            ResultTile(label: 'Principal', value: r'$15,000'),
            ResultTile(label: 'Total Interest', value: r'$2,400'),
            ResultTile(label: 'Down Payment', value: r'$3,000'),
          ],
        ),
      ));
      await tester.pump();
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Total Interest'), findsOneWidget);
      expect(find.text('Down Payment'), findsOneWidget);
    });

    testWidgets('renders APR tile', (tester) async {
      await tester.pumpWidget(_host(
        const ResultTile(label: 'APR', value: '6.9%'),
      ));
      await tester.pump();
      expect(find.text('APR'), findsOneWidget);
      expect(find.text('6.9%'), findsOneWidget);
    });
  });

  group('CalcwiseHeroCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseHeroCard(
          label: 'Monthly Payment',
          value: r'$349',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('MONTHLY PAYMENT'), findsOneWidget);
      expect(find.text(r'$349'), findsOneWidget);
    });

    testWidgets('renders secondary text', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseHeroCard(
          label: 'Monthly Payment',
          value: r'$349',
          secondary: '60-month term',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('60-month term'), findsOneWidget);
    });

    testWidgets('renders stats row', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseHeroCard(
          label: 'Monthly Payment',
          value: r'$349',
          stats: [
            (label: 'Total Interest', value: r'$2,400'),
            (label: 'APR', value: '6.9%'),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TOTAL INTEREST'), findsOneWidget);
      expect(find.text('APR'), findsOneWidget);
    });

    testWidgets('renders badge', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseHeroCard(
          label: 'Monthly Payment',
          value: r'$349',
          badges: [CalcwiseHeroBadge(label: '60 mo')],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('60 mo'), findsOneWidget);
    });
  });

  group('SectionCard', () {
    testWidgets('renders title and children', (tester) async {
      await tester.pumpWidget(_host(
        const SectionCard(
          title: 'Loan Details',
          children: [
            ResultTile(label: 'Loan Amount', value: r'$18,000'),
            ResultTile(label: 'Term', value: '60 months'),
          ],
        ),
      ));
      await tester.pump();
      expect(find.text('Loan Details'), findsOneWidget);
      expect(find.text('Loan Amount'), findsOneWidget);
      expect(find.text('Term'), findsOneWidget);
    });

    testWidgets('renders with single child', (tester) async {
      await tester.pumpWidget(_host(
        const SectionCard(
          title: 'Trade-In',
          children: [Text('No trade-in applied')],
        ),
      ));
      await tester.pump();
      expect(find.text('Trade-In'), findsOneWidget);
      expect(find.text('No trade-in applied'), findsOneWidget);
    });
  });

  group('CalcwiseEmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseEmptyState(
          icon: Icons.directions_car_rounded,
          title: 'No saved loans',
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
      expect(find.text('No saved loans'), findsOneWidget);
    });

    testWidgets('renders body and action button', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_host(
        CalcwiseEmptyState(
          icon: Icons.calculate_rounded,
          title: 'No calculations',
          body: 'Calculate your first auto loan above.',
          actionLabel: 'Calculate',
          onAction: () => tapped = true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Calculate'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without action when not provided', (tester) async {
      await tester.pumpWidget(_host(
        const CalcwiseEmptyState(
          icon: Icons.directions_car_rounded,
          title: 'No data',
        ),
      ));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
