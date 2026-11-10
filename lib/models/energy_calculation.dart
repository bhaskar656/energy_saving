class EnergyCalculation {
  const EnergyCalculation({
    required this.dailyKwh,
    required this.weeklyKwh,
    required this.monthlyKwh,
    required this.dailyCost,
    required this.weeklyCost,
    required this.monthlyCost,
  });

  final double dailyKwh;
  final double weeklyKwh;
  final double monthlyKwh;
  final double dailyCost;
  final double weeklyCost;
  final double monthlyCost;
}