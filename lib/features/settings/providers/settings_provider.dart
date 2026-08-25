import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/features/settings/models/settings_model.dart';
import 'package:sahibz_inventory/features/settings/repositories/settings_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool isLoaded;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isLoaded,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final AuditLogRepository _auditLogRepo;

  SettingsNotifier(this._repository, this._auditLogRepo) : super(const SettingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAppSettings();
    if (result.isSuccess) {
      state = state.copyWith(
        settings: result.value,
        isLoading: false,
        isLoaded: true,
        clearError: true,
      );
      unawaited(AppLogger.setFileLogging(enabled: result.value.logToFile));
      CurrencyFormatter.setSymbol(result.value.currencySymbol);
      AppLogger.i('Settings loaded successfully');
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<String?> saveAll(AppSettings settings) async {
    state = state.copyWith(isSaving: true, clearError: true);

    final result = await _repository.updateAll(settings);
    if (result.isSuccess) {
      state = state.copyWith(
        settings: settings,
        isSaving: false,
        clearError: true,
      );
      unawaited(AppLogger.setFileLogging(enabled: settings.logToFile));
      CurrencyFormatter.setSymbol(settings.currencySymbol);
      AppLogger.i('Settings saved successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'setting',
        details: 'All settings updated',
      ));
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(isSaving: false, error: errorMsg);
      AppLogger.e('Settings save failed: $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> updateSingle(String key, String value) async {
    final result = await _repository.update(key, value);
    if (result.isSuccess) {
      state = state.copyWith(
        settings: state.settings.applySetting(key, value),
        clearError: true,
      );
      if (key == 'currency_symbol') {
        CurrencyFormatter.setSymbol(value);
      }
      AppLogger.i('Setting updated: $key = $value');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'setting',
        details: 'Setting $key changed to $value',
      ));
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      return errorMsg;
    }
  }

  Future<String?> toggleTheme() async {
    final newTheme = state.settings.isDarkTheme ? 'light' : 'dark';
    final updated = state.settings.copyWith(theme: newTheme);
    return saveAll(updated);
  }

  void updateSettings(AppSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return SettingsNotifier(repository, auditLogRepo);
});
