import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Smoke test — vérifie que les widgets de base se construisent sans crash
// N'initialise pas Firebase (incompatible avec l'environnement de test)
void main() {
  group('Smoke — widgets de base', () {
    testWidgets('MaterialApp se construit sans crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('AutoLoan'))),
        ),
      );
      expect(find.text('AutoLoan'), findsOneWidget);
    });

    testWidgets('TextFormField accepte des inputs numériques', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '25000');
      expect(find.text('25000'), findsOneWidget);
    });

    testWidgets('DropdownButton se construit sans crash', (tester) async {
      String selected = 'ON';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: DropdownButton<String>(
                value: selected,
                items: const [
                  DropdownMenuItem(value: 'ON', child: Text('Ontario')),
                  DropdownMenuItem(value: 'QC', child: Text('Québec')),
                  DropdownMenuItem(value: 'BC', child: Text('British Columbia')),
                ],
                onChanged: (v) => setState(() => selected = v!),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Ontario'), findsOneWidget);
    });
  });
}
