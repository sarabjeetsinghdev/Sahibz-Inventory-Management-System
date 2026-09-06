import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/features/settings/repositories/settings_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final String? username;
  const AuthState({this.isAuthenticated = false, this.error, this.username});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String username, String password) async {
    final repo = ref.read(settingsRepositoryProvider);
    final storedUserResult = await repo.get('username');
    final storedUser = storedUserResult.value ?? 'admin';
    final storedPwResult = await repo.get('password');
    final storedPw = storedPwResult.value ?? 'admin';
    if (username == storedUser && password == storedPw) {
      state = AuthState(isAuthenticated: true, username: username);
      unawaited(ref.read(auditLogRepositoryProvider).logAction(
        userId: username,
        action: 'login',
        entityType: 'auth',
        details: 'User $username logged in',
      ));
      return true;
    } else {
      state = const AuthState(error: 'Invalid username or password');
      return false;
    }
  }

  void clearError() {
    state = AuthState(
      isAuthenticated: state.isAuthenticated,
      username: state.username,
    );
  }

  Future<String?> changeCredentials(String oldPassword, String newUsername, String newPassword) async {
    final repo = ref.read(settingsRepositoryProvider);
    final storedPwResult = await repo.get('password');
    final storedPw = storedPwResult.value ?? 'admin';
    if (oldPassword != storedPw) {
      return 'Current password is incorrect';
    }
    await repo.update('username', newUsername);
    await repo.update('password', newPassword);
    state = AuthState(isAuthenticated: true, username: newUsername);
    unawaited(ref.read(auditLogRepositoryProvider).logAction(
      userId: newUsername,
      action: 'update',
      entityType: 'credential',
      details: 'Credentials changed',
    ));
    return null;
  }

  void logout() {
    unawaited(ref.read(auditLogRepositoryProvider).logAction(
      userId: state.username ?? 'unknown',
      action: 'logout',
      entityType: 'auth',
      details: 'User ${state.username} logged out',
    ));
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
