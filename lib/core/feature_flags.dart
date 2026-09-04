import 'package:sahibz_inventory/features/settings/repositories/settings_repository.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:flutter_riverpod/legacy.dart';

class FeatureFlags {
  final Map<String, bool> _flags;
  const FeatureFlags(this._flags);

  bool isEnabled(String key) => _flags[key] ?? true;

  bool get dashboard => isEnabled('dashboard');
  bool get products => isEnabled('products');
  bool get categories => isEnabled('categories');
  bool get inventory => isEnabled('inventory');
  bool get purchases => isEnabled('purchases');
  bool get sales => isEnabled('sales');
  bool get suppliers => isEnabled('suppliers');
  bool get customers => isEnabled('customers');
  bool get reports => isEnabled('reports');
  bool get auditLogs => isEnabled('audit_logs');
  bool get settings => true;

  Map<String, bool> toMap() => Map.unmodifiable(_flags);

  FeatureFlags copyWithFlag(String key, bool value) {
    if (key == 'settings') return this;
    final map = Map<String, bool>.from(_flags);
    map[key] = value;
    return FeatureFlags(map);
  }

  static const List<String> allKeys = [
    'dashboard',
    'products',
    'categories',
    'inventory',
    'purchases',
    'sales',
    'suppliers',
    'customers',
    'reports',
    'audit_logs',
  ];
}

class FeatureFlagsNotifier extends StateNotifier<FeatureFlags> {
  final SettingsRepository _repo;
  final AppDatabase _db;

  FeatureFlagsNotifier(this._repo, this._db) : super(const FeatureFlags({})) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getAll();
    if (result.isSuccess) {
      final map = result.value;
      final flags = <String, bool>{};
      for (final key in FeatureFlags.allKeys) {
        final dbKey = 'feature_$key';
        if (map.containsKey(dbKey)) {
          flags[key] = map[dbKey]!.toLowerCase() == 'true';
        }
      }
      state = FeatureFlags(flags);
    }
  }

  Future<void> setFlag(String key, bool value) async {
    if (key == 'settings') return;
    state = state.copyWithFlag(key, value);
    await _repo.update('feature_$key', value.toString());
  }

  Future<void> refresh() async => _load();
}

final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, FeatureFlags>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  final db = ref.watch(databaseProvider);
  return FeatureFlagsNotifier(repo, db);
});
