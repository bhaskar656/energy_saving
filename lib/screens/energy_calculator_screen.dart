import 'package:energy_saving/models/energy_calculation.dart';
import 'package:energy_saving/services/energy_calculator.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/dashboard_components.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class EnergyCalculatorScreen extends StatefulWidget {
  const EnergyCalculatorScreen({super.key, this.initialTariffPerKwh});

  final double? initialTariffPerKwh;

  @override
  State<EnergyCalculatorScreen> createState() => _EnergyCalculatorScreenState();
}

class _EnergyCalculatorScreenState extends State<EnergyCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applianceController = TextEditingController();
  final _powerController = TextEditingController();
  final _hoursController = TextEditingController();
  final _tariffController = TextEditingController();
  final _calculator = const EnergyCalculator();
  EnergyCalculation? _calculation;

  @override
  void initState() {
    super.initState();
    final initialTariff = widget.initialTariffPerKwh;
    if (initialTariff != null) {
      _tariffController.text = initialTariff.toString();
    }
  }

  @override
  void dispose() {
    _applianceController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an appliance.';
    return null;
  }

  String? _validatePower(String? value) {
    final power = double.tryParse(value?.trim() ?? '');
    if (power == null || !power.isFinite || power <= 0) {
      return 'Enter a value greater than 0 W.';
    }
    return null;
  }

  String? _validateHours(String? value) {
    final hours = double.tryParse(value?.trim() ?? '');
    if (hours == null || !hours.isFinite || hours < 0 || hours > 24) {
      return 'Enter a value from 0 to 24 hours.';
    }
    return null;
  }

  String? _validateTariff(String? value) {
    final tariff = double.tryParse(value?.trim() ?? '');
    if (tariff == null || !tariff.isFinite || tariff < 0) {
      return 'Enter a tariff of 0 or more.';
    }
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _calculation = _calculator.calculate(
        powerWatts: double.parse(_powerController.text.trim()),
        hoursPerDay: double.parse(_hoursController.text.trim()),
        tariffPerKwh: double.parse(_tariffController.text.trim()),
      );
    });
  }

  void _clearResult() {
    if (_calculation != null) setState(() => _calculation = null);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                EcoHeader(
                  eyebrow: 'Quick maths',
                  title: 'Energy calculator',
                  subtitle: 'Estimate kWh and cost for any appliance',
                  illustration: const EcoIllustration(
                    mainIcon: Icons.calculate_rounded,
                    accent: AppPalette.teal,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Estimate appliance use',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the appliance’s rated power, typical daily hours, and your electricity tariff.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      EcoCard(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _applianceController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Appliance',
                                  prefixIcon: Icon(Icons.devices_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: _requiredText,
                                onChanged: (_) => _clearResult(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _powerController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Power consumption',
                                  suffixText: 'W',
                                  prefixIcon: Icon(Icons.bolt_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validatePower,
                                onChanged: (_) => _clearResult(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _hoursController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Average daily use',
                                  suffixText: 'hours',
                                  prefixIcon: Icon(Icons.schedule_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validateHours,
                                onChanged: (_) => _clearResult(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tariffController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Electricity tariff',
                                  prefixText: '₹ ',
                                  suffixText: '/ kWh',
                                  prefixIcon: Icon(Icons.payments_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validateTariff,
                                onChanged: (_) => _clearResult(),
                                onFieldSubmitted: (_) => _calculate(),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _calculate,
                                icon: const Icon(Icons.calculate_rounded),
                                label: const Text('Calculate estimate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_calculation case final calculation?) ...[
                        const SizedBox(height: 28),
                        SectionHeader(
                          title:
                              'Estimated use · ${_applianceController.text.trim()}',
                          subtitle:
                              'Based on the entered tariff and a 30-day estimate month.',
                          icon: Icons.insights_rounded,
                          accent: AppPalette.emeraldDeep,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 620 ? 3 : 1;
                            const spacing = 12.0;
                            final width =
                                (constraints.maxWidth -
                                    spacing * (columns - 1)) /
                                columns;
                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _EstimateCard(
                                    period: 'Daily',
                                    kwh: calculation.dailyKwh,
                                    cost: calculation.dailyCost,
                                    accent: AppPalette.sky,
                                    icon: Icons.today_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _EstimateCard(
                                    period: 'Weekly · 7 days',
                                    kwh: calculation.weeklyKwh,
                                    cost: calculation.weeklyCost,
                                    accent: AppPalette.teal,
                                    icon: Icons.date_range_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _EstimateCard(
                                    period: 'Monthly · 30 days',
                                    kwh: calculation.monthlyKwh,
                                    cost: calculation.monthlyCost,
                                    accent: AppPalette.emeraldDeep,
                                    icon: Icons.calendar_month_rounded,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Estimate only. Actual use and charges may vary.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.period,
    required this.kwh,
    required this.cost,
    required this.accent,
    required this.icon,
  });

  final String period;
  final double kwh;
  final double cost;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return EcoCard(
      padding: const EdgeInsets.all(18),
      gradient: AppPalette.washFor(accent),
      borderColor: accent.withValues(alpha: 0.22),
      shadow: AppPalette.shadowFor(accent, opacity: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, accent: accent, size: 40, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(period, style: textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${kwh.toStringAsFixed(2)} kWh',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accentForeground(context, accent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${cost.toStringAsFixed(2)} estimated cost',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}