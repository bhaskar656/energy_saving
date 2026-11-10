// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:energy_saving/app.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/services/auth_service.dart';

class _TestAuthSession implements AuthSession {
  const _TestAuthSession();

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('Energy Saving Reminder launches with Material 3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const EnergySavingApp(authSession: _TestAuthSession()),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
    expect(find.text('Energy Saving Reminder'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });
}
