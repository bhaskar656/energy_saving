import 'dart:async';

import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/home_screen.dart';
import 'package:energy_saving/screens/login_screen.dart';
import 'package:energy_saving/services/auth_service.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authSession,
    this.settingsRepository,
    this.onThemeModeChanged,
  });

  final AuthSession? authSession;
  final UserSettingsRepository? settingsRepository;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthSession _authSession =
      widget.authSession ?? AuthService();
  late final UserSettingsRepository _settingsRepository =
      widget.settingsRepository ??
      UserSettingsRepository(databaseHelper: DatabaseHelper.instance);
  User? _user;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final user = await _authSession.currentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _onAuthenticated(User user) {
    widget.onThemeModeChanged?.call(ThemeMode.light);
    setState(() {
      _user = user;
      _loadFailed = false;
    });
  }

  Future<void> _logout() async {
    try {
      await _authSession.logout();
      if (!mounted) return;
      widget.onThemeModeChanged?.call(ThemeMode.light);
      setState(() => _user = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: AppLoadingIndicator(message: 'Preparing your dashboard'),
        ),
      );
    }

    if (_loadFailed) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppFeedbackPanel(
                icon: Icons.cloud_off_rounded,
                title: 'Your local session could not be loaded.',
                message:
                    'The app could not read its saved data on this device.',
                isError: true,
                actionLabel: 'Try again',
                actionIcon: Icons.refresh_rounded,
                onAction: () => unawaited(_restoreSession()),
              ),
            ),
          ),
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return LoginScreen(
        authSession: _authSession,
        onAuthenticated: _onAuthenticated,
      );
    }

    return HomeScreen(
      user: user,
      onLogout: _logout,
      settingsRepository: _settingsRepository,
      onThemeModeChanged: widget.onThemeModeChanged,
    );
  }
}