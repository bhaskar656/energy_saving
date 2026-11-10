import 'package:energy_saving/services/energy_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = EnergyCalculator();

  test('calculates daily, weekly, monthly use and estimated cost', () {
    final result = calculator.calculate(
      powerWatts: 100,
      hoursPerDay: 5,
      tariffPerKwh: 8,
    );

    expect(result.dailyKwh, 0.5);
    expect(result.weeklyKwh, 3.5);
    expect(result.monthlyKwh, 15);
    expect(result.dailyCost, 4);
    expect(result.weeklyCost, 28);
    expect(result.monthlyCost, 120);
  });

  test('allows zero daily hours and a zero tariff', () {
    final result = calculator.calculate(
      powerWatts: 75,
      hoursPerDay: 0,
      tariffPerKwh: 0,
    );

    expect(result.dailyKwh, 0);
    expect(result.monthlyCost, 0);
  });

  test('rejects invalid numeric inputs', () {
    expect(
      () => calculator.calculate(
        powerWatts: 0,
        hoursPerDay: 1,
        tariffPerKwh: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculator.calculate(
        powerWatts: 100,
        hoursPerDay: 24.1,
        tariffPerKwh: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculator.calculate(
        powerWatts: 100,
        hoursPerDay: 1,
        tariffPerKwh: -1,
      ),
      throwsArgumentError,
    );
  });
}