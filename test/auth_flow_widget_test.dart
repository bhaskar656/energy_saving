import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/screens/login_screen.dart';
import 'package:energy_saving/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSession implements AuthSession {
  _FakeAuthSession(this.user);

  final User user;
  int loginCalls = 0;
  int registerCalls = 0;
  AuthException? loginError;

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCalls++;
    final error = loginError;
    if (error != null) throw error;
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return User(name: name, email: email);
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('login validates fields, shows auth errors, and authenticates', (
    tester,
  ) async {
    final user = User(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
    );
    final authSession = _FakeAuthSession(user)
      ..loginError = const AuthException('Email or password is incorrect.');
    User? authenticatedUser;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authSession: authSession,
          onAuthenticated: (value) => authenticatedUser = value,
        ),
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(authSession.loginCalls, 0);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'incorrect');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);

    authSession.loginError = null;
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(authenticatedUser?.id, user.id);
  });

  testWidgets('registration validates matching passwords before saving', (
    tester,
  ) async {
    final authSession = _FakeAuthSession(
      User(name: 'Test User', email: 'test@example.com'),
    );
    User? registeredUser;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authSession: authSession,
          onAuthenticated: (value) => registeredUser = value,
        ),
      ),
    );
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(1), 'test@example.com');
    await tester.enterText(fields.at(2), 'secure-demo-123');
    await tester.enterText(fields.at(3), 'different-password');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(authSession.registerCalls, 0);

    await tester.enterText(fields.at(3), 'secure-demo-123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(authSession.registerCalls, 1);
    expect(registeredUser?.email, 'test@example.com');
  });
}