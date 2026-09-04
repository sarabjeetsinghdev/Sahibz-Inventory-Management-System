import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/feature_flags.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class FeatureFlagsScreen extends ConsumerStatefulWidget {
  const FeatureFlagsScreen({super.key});

  @override
  ConsumerState<FeatureFlagsScreen> createState() => _FeatureFlagsScreenState();
}

class _FeatureFlagsScreenState extends ConsumerState<FeatureFlagsScreen> {
  late Map<String, bool> _local;

  static const _labels = {
    'dashboard': ('Dashboard', CupertinoIcons.house_alt),
    'products': ('Products', CupertinoIcons.tray_2),
    'categories': ('Categories', CupertinoIcons.folder),
    'inventory': ('Inventory', CupertinoIcons.square_list_fill),
    'purchases': ('Purchases', CupertinoIcons.cart),
    'sales': ('Sales', CupertinoIcons.money_dollar),
    'suppliers': ('Suppliers', CupertinoIcons.briefcase),
    'customers': ('Customers', CupertinoIcons.person_3),
    'reports': ('Reports', CupertinoIcons.chart_bar),
    'audit_logs': ('Audit Logs', CupertinoIcons.shield),
  };

  static const _groups = [
    ('MAIN', CupertinoIcons.square_grid_2x2, ['dashboard']),
    ('INVENTORY', CupertinoIcons.tray_2, ['products', 'categories', 'inventory']),
    ('TRANSACTIONS', CupertinoIcons.cart, ['purchases', 'sales']),
    ('RELATIONS', CupertinoIcons.person_3, ['suppliers', 'customers']),
    ('MANAGEMENT', CupertinoIcons.chart_bar, ['reports', 'audit_logs']),
  ];

  @override
  void initState() {
    super.initState();
    final flags = ref.read(featureFlagsProvider);
    _local = {for (final k in FeatureFlags.allKeys) k: flags.isEnabled(k)};
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _local.values.where((v) => v).length;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Features'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                '$enabledCount of ${FeatureFlags.allKeys.length} sections visible',
                textAlign: TextAlign.center,
                style: AppTypography.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            ..._groups.map((group) => _buildGroupCard(
                  group.$1,
                  group.$2,
                  group.$3,
                  context.primaryColor,
                  context.borderColor,
                  context.surfaceColor,
                  context.primaryTextColor,
                  context.secondaryTextColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String title, IconData icon, List<String> keys, Color primaryColor, Color borderColor,
      Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.poppins(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...keys.map((key) {
            final label = _labels[key]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(label.$2, size: 16, color: secondaryTextColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label.$1,
                        style: AppTypography.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                  ),
                  CustomPointer(
                    child: CupertinoSwitch(
                      value: _local[key] ?? true,
                      onChanged: (v) {
                        setState(() => _local[key] = v);
                        ref.read(featureFlagsProvider.notifier).setFlag(key, v);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
