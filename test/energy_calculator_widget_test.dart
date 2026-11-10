import 'package:energy_saving/screens/energy_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses saved tariff and renders daily, weekly, and monthly estimates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EnergyCalculatorScreen(initialTariffPerKwh: 8),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(fields.at(3)).controller?.text, '8.0');

    await tester.enterText(fields.at(0), 'Fan');
    await tester.enterText(fields.at(1), '100');
    await tester.enterText(fields.at(2), '5');
    expect(tester.widget<TextFormField>(fields.at(0)).controller?.text, 'Fan');
    expect(tester.widget<TextFormField>(fields.at(1)).controller?.text, '100');
    expect(tester.widget<TextFormField>(fields.at(2)).controller?.text, '5');
    await tester.tap(find.text('Calculate estimate'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Estimated use · Fan'), findsOneWidget);
    expect(find.text('0.50 kWh'), findsOneWidget);
    expect(find.text('3.50 kWh'), findsOneWidget);
    expect(find.text('15.00 kWh'), findsOneWidget);
    expect(find.text('₹4.00 estimated cost'), findsOneWidget);
    expect(find.text('₹28.00 estimated cost'), findsOneWidget);
    expect(find.text('₹120.00 estimated cost'), findsOneWidget);

    await tester.enterText(fields.at(2), '2');
    await tester.pumpAndSettle();
    expect(find.text('15.00 kWh'), findsNothing);
  });
}