class DashboardSummary {
  const DashboardSummary({
    required this.todayUsageKwh,
    required this.todayRecordCount,
    required this.weekUsageKwh,
    required this.weekRecordCount,
    required this.monthUsageKwh,
    required this.monthRecordCount,
    required this.activeReminderCount,
    required this.monthlyTargetKwh,
    required this.tariffPerKwh,
  });

  final double todayUsageKwh;
  final int todayRecordCount;
  final double weekUsageKwh;
  final int weekRecordCount;
  final double monthUsageKwh;
  final int monthRecordCount;
  final int activeReminderCount;
  final double? monthlyTargetKwh;
  final double? tariffPerKwh;
}