import 'package:energy_saving/models/energy_calculation.dart';

class EnergyCalculator {
  const EnergyCalculator();

  static const daysPerWeek = 7;
  static const daysPerEstimateMonth = 30;

  EnergyCalculation calculate({
    required double powerWatts,
    required double hoursPerDay,
    required double tariffPerKwh,
  }) {
    if (!powerWatts.isFinite || powerWatts <= 0) {
      throw ArgumentError.value(powerWatts, 'powerWatts');
    }
    if (!hoursPerDay.isFinite || hoursPerDay < 0 || hoursPerDay > 24) {
      throw ArgumentError.value(hoursPerDay, 'hoursPerDay');
    }
    if (!tariffPerKwh.isFinite || tariffPerKwh < 0) {
      throw ArgumentError.value(tariffPerKwh, 'tariffPerKwh');
    }

    final dailyKwh = powerWatts * hoursPerDay / 1000;
    final weeklyKwh = dailyKwh * daysPerWeek;
    final monthlyKwh = dailyKwh * daysPerEstimateMonth;

    return EnergyCalculation(
      dailyKwh: dailyKwh,
      weeklyKwh: weeklyKwh,
      monthlyKwh: monthlyKwh,
      dailyCost: dailyKwh * tariffPerKwh,
      weeklyCost: weeklyKwh * tariffPerKwh,
      monthlyCost: monthlyKwh * tariffPerKwh,
    );
  }
}