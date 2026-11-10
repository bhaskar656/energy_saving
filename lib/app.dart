import 'package:energy_saving/screens/auth_gate.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/services/auth_service.dart';
import 'package:energy_saving/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EnergySavingApp extends StatefulWidget {
  const EnergySavingApp({
    super.key,
    this.authSession,
    this.settingsRepository,
  });

  final AuthSession? authSession;
  final UserSettingsRepository? settingsRepository;

  @override
  State<EnergySavingApp> createState() => _EnergySavingAppState();
}

class _EnergySavingAppState extends State<EnergySavingApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _setThemeMode(ThemeMode themeMode) {
    if (_themeMode != themeMode) setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Energy Saving Reminder',
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: AuthGate(
        authSession: widget.authSession,
        settingsRepository: widget.settingsRepository,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}