import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/session_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:energy_saving/utils/validators.dart';

abstract interface class AuthSession {
  Future<User?> currentUser();
  Future<User> login({required String email, required String password});
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Demo-only local authentication; this fast hash is not production password storage.
class AuthService implements AuthSession {
  AuthService({DatabaseHelper? databaseHelper})
    : _userRepository = UserRepository(
        databaseHelper: databaseHelper ?? DatabaseHelper.instance,
      ),
      _sessionRepository = SessionRepository(
        databaseHelper: databaseHelper ?? DatabaseHelper.instance,
      );

  final UserRepository _userRepository;
  final SessionRepository _sessionRepository;

  @override
  Future<User?> currentUser() async {
    final userId = await _sessionRepository.getCurrentUserId();
    if (userId == null) return null;

    final user = await _userRepository.findById(userId);
    if (user == null) await _sessionRepository.clear();
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (Validators.name(normalizedName) != null ||
        Validators.email(normalizedEmail) != null ||
        Validators.password(password) != null) {
      throw const AuthException('Check your name, email, and password.');
    }

    if (await _userRepository.findByEmail(normalizedEmail) != null) {
      throw const AuthException('An account with this email already exists.');
    }

    final id = await _userRepository.insert(
      User(
        name: normalizedName,
        email: normalizedEmail,
        passwordHash: _createPasswordHash(password),
      ),
    );
    final user = await _userRepository.findById(id);
    if (user == null) {
      throw const AuthException('The account could not be loaded.');
    }

    await _sessionRepository.saveCurrentUser(id);
    return user;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (Validators.email(normalizedEmail) != null || password.isEmpty) {
      throw const AuthException('Email or password is incorrect.');
    }

    final user = await _userRepository.findByEmail(normalizedEmail);
    if (user == null || !_verifyPassword(password, user.passwordHash)) {
      throw const AuthException('Email or password is incorrect.');
    }

    await _sessionRepository.saveCurrentUser(user.id!);
    return user;
  }

  @override
  Future<void> logout() => _sessionRepository.clear();

  String _createPasswordHash(String password) {
    final random = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final digest = sha256.convert(utf8.encode('$salt:$password'));
    return 'sha256-v1:$salt:$digest';
  }

  bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 3 || parts.first != 'sha256-v1') return false;

    final candidate = sha256.convert(utf8.encode('${parts[1]}:$password'));
    return _constantTimeEquals(candidate.toString(), parts[2]);
  }

  bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }
}