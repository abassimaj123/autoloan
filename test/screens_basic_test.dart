import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:auto_loan/country/ca/ca_logic.dart';
import 'package:auto_loan/country/us/us_logic.dart';
import 'package:auto_loan/country/uk/uk_logic.dart';

void main() {
  group('Format — affichage des résultats', () {
    test('Formatage currency CAD', () {
      final fmt = NumberFormat.currency(locale: 'en_CA', symbol: r'$');
      expect(fmt.format(1234.56), r'$1,234.56');
    });

    test('Formatage currency USD', () {
      final fmt = NumberFormat.currency(locale: 'en_US', symbol: r'$');
      expect(fmt.format(25000), r'$25,000.00');
    });

    test('Formatage pourcentage taux', () {
      final fmt = NumberFormat('#,##0.00');
      expect(fmt.format(7.9), '7.90');
    });
  });

  group('Widget — éléments UI de base', () {
    testWidgets('Card résultat paiement mensuel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Monthly Payment'),
                  Text(
                    r'$587.43',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Monthly Payment'), findsOneWidget);
      expect(find.text(r'$587.43'), findsOneWidget);
    });

    testWidgets('DropdownButton provinces se construit', (tester) async {
      String selected = 'ON';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (ctx, setState) => Scaffold(
              body: DropdownButton<String>(
                value: selected,
                items: const [
                  DropdownMenuItem(value: 'ON', child: Text('Ontario')),
                  DropdownMenuItem(value: 'QC', child: Text('Québec')),
                  DropdownMenuItem(value: 'AB', child: Text('Alberta')),
                ],
                onChanged: (v) => setState(() => selected = v!),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Ontario'), findsOneWidget);
    });

    testWidgets('Champ montant véhicule accepte valeur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Vehicle Price'),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '35000');
      expect(find.text('35000'), findsOneWidget);
    });
  });

  group('Regression guard — CA', () {
    test('RG-CA-1: paiement ON 30k @ 7.9% / 60 mois', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        isBiWeekly: false,
      );
      expect(r.monthlyPayment, closeTo(587, 5.0));
    });

    test('RG-CA-2: taxe ON = 13% sur prix véhicule', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 0,
        annualRate: 5.0,
        termMonths: 60,
        provinceCode: 'ON',
        isBiWeekly: false,
      );
      expect(r.taxAmount, closeTo(3900, 0.01));
    });

    test('RG-CA-3: taxe QC = 14.975%', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 0,
        annualRate: 5.0,
        termMonths: 60,
        provinceCode: 'QC',
        isBiWeekly: false,
      );
      expect(r.taxAmount, closeTo(4492.50, 1.0));
    });
  });

  group('Regression guard — US', () {
    test('RG-US-1: paiement 25k @ 6.5% / 60 mois', () {
      final r = USCalculation.calculate(
        vehiclePrice: 25000,
        downPayment: 5000,
        tradeInValue: 0,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 6.5,
        termMonths: 60,
        creditScore: CreditScore.excellent,
        isBiWeekly: false,
      );
      expect(r.monthlyPayment, closeTo(377.42, 1.0));
    });
  });

  group('Regression guard — UK', () {
    test('RG-UK-1: paiement 15k GBP @ 8.9% / 48 mois', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 15000,
        downPayment: 3000,
        annualRate: 8.9,
        termMonths: 48,
        isBiWeekly: false,
      );
      expect(r.monthlyPayment, closeTo(295, 10.0));
    });
  });
}
