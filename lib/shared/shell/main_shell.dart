// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/features/auth/providers/auth_provider.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/core/feature_flags.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 1024;

    final authState = ref.watch(authProvider);
    final settingsState = ref.watch(settingsProvider);
    final flags = ref.watch(featureFlagsProvider);

    final navItemColor = context.isDarkTheme ? CupertinoColors.white : CupertinoColors.darkBackgroundGray;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              Container(
                width: 260,
                color: context.surfaceColor,
                child: Column(
                  children: [
                    _buildSidebarHeader(context.primaryColor, context.primaryTextColor, context.secondaryTextColor),
                    Container(height: 1, color: context.borderColor),
                    Expanded(child: _buildNavList(navItemColor, context.primaryTextColor, context.secondaryTextColor, context.borderColor, brightness, isDesktop, flags)),
                    _buildSidebarFooter(context.primaryTextColor, context.primaryColor, brightness),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context.primaryColor, context.primaryTextColor, context.secondaryTextColor, context.borderColor, brightness,
                      authState, settingsState, isDesktop, context.surfaceColor),
                  Container(height: 1, color: context.borderColor),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(Color primary, Color text, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.square_list, color: CupertinoColors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SahibZ', style: AppTypography.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: text)),
              Text('Inventory System', style: AppTypography.poppins(fontSize: 12, color: secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavList(Color primary, Color text, Color secondaryText, Color border, Brightness brightness,
      bool isDesktop, FeatureFlags flags) {
    final showInventory = flags.inventory;
    final showInventorySection = flags.products || flags.categories || showInventory;
    final showTransactionsSection = flags.purchases || flags.sales;
    final showRelationsSection = flags.suppliers || flags.customers;
    final showManagementSection = flags.reports || flags.auditLogs || flags.settings;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (flags.dashboard) ...[
          _sectionLabel('MAIN', secondaryText),
          _navItem(CupertinoIcons.house_alt, 'dashboard'.tr(), '/dashboard', primary, text, brightness),
          const SizedBox(height: 6.0),
        ],
        if (showInventorySection) ...[
          _sectionLabel('INVENTORY', secondaryText),
          if (flags.products) _navItem(CupertinoIcons.tray_2, 'products'.tr(), '/products', primary, text, brightness),
          if (flags.categories) _navItem(CupertinoIcons.folder, 'categories'.tr(), '/categories', primary, text, brightness),
          if (showInventory) _navItem(CupertinoIcons.square_list_fill, 'inventory'.tr(), '/inventory', primary, text, brightness),
          const SizedBox(height: 6.0),
        ],
        if (showTransactionsSection) ...[
          _sectionLabel('TRANSACTIONS', secondaryText),
          if (flags.purchases) _navItem(CupertinoIcons.cart, 'purchases'.tr(), '/purchases', primary, text, brightness),
          if (flags.sales) _navItem(CupertinoIcons.money_dollar, 'sales'.tr(), '/sales', primary, text, brightness),
          const SizedBox(height: 6.0),
        ],
        if (showRelationsSection) ...[
          _sectionLabel('RELATIONS', secondaryText),
          if (flags.suppliers) _navItem(CupertinoIcons.briefcase, 'suppliers'.tr(), '/suppliers', primary, text, brightness),
          if (flags.customers) _navItem(CupertinoIcons.person_3, 'customers'.tr(), '/customers', primary, text, brightness),
          const SizedBox(height: 6.0),
        ],
        if (showManagementSection) ...[
          _sectionLabel('MANAGEMENT', secondaryText),
          if (flags.reports) _navItem(CupertinoIcons.chart_bar, 'reports'.tr(), '/reports', primary, text, brightness),
          if (flags.auditLogs) _navItem(CupertinoIcons.shield, 'audit_logs'.tr(), '/audit-logs', primary, text, brightness),
          if (flags.settings) _navItem(CupertinoIcons.gear, 'settings'.tr(), '/settings', primary, text, brightness),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(label,
          style: AppTypography.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText, letterSpacing: 1.2)),
    );
  }

  Widget _navItem(IconData icon, String label, String route, Color primary, Color text, Brightness brightness) {
    final location = GoRouterState.of(context).uri.toString();
    final isActive = route == '/dashboard' ? location == '/dashboard' : location.startsWith(route);
    final bg = isActive
        ? (brightness == Brightness.dark ? primary.withOpacity(0.28) : primary.withOpacity(0.14))
        : CupertinoColors.transparent;
    final fg = isActive ? primary : text;
    return CustomPointer(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: primary.withOpacity(0.35)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? primary : CupertinoColors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 9),
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.poppins(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color primary, Color text, Color secondaryText, Color border, Brightness brightness,
      AuthState authState, SettingsState settingsState,
      bool isDesktop, Color surface) {
    // const initials = 'A';
    return Container(
      height: 48,
      color: surface,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
      child: Row(
        children: [
          Text(_getPageTitle(), style: AppTypography.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: text)),
          const Spacer(),
          CustomPointer(
            onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(
                settingsState.settings.isDarkTheme ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                size: 22, color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showUserMenu(Color primary, Color text, Color secondaryText, Brightness brightness) {
  //   showCustomModal(
  //     context: context,
  //     height: 0.53,
  //     builder: (ctx) => Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Column(
  //         children: [
  //           Container(
  //             margin: const EdgeInsets.symmetric(vertical: 16),
  //             width: 56, height: 56,
  //             decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(28)),
  //             alignment: Alignment.center,
  //             child: Text('A', style: AppTypography.poppins(color: CupertinoColors.white, fontSize: 22, fontWeight: FontWeight.w600)),
  //           ),
  //           Text('Administrator', style: AppTypography.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
  //           const SizedBox(height: 4),
  //           Text('admin@sahibz.com', style: AppTypography.poppins(fontSize: 13, color: secondaryText)),
  //           const SizedBox(height: 24),
  //           _menuTile(ctx, CupertinoIcons.gear, 'settings'.tr(), () { Navigator.of(ctx).pop(); context.go('/settings'); }),
  //           const SizedBox(height: 8),
  //           _menuTile(ctx, CupertinoIcons.square_arrow_left, 'logout'.tr(), () { Navigator.of(ctx).pop(); _showLogoutConfirm(); },
  //               isDestructive: true),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _menuTile(BuildContext ctx, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
  //   final color = isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.label;
  //   return CustomPointer(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //       decoration: BoxDecoration(
  //         color: CupertinoColors.systemGrey6,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, size: 20, color: color),
  //           const SizedBox(width: 12),
  //           Text(label, style: AppTypography.poppins(fontSize: 16, color: color)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSidebarFooter(Color text, Color primary, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomPointer(
        onTap: () => _showLogoutConfirm(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: CupertinoColors.destructiveRed.withOpacity(0.1),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.square_arrow_left, size: 20, color: CupertinoColors.destructiveRed),
              const SizedBox(width: 12),
              Text('logout'.tr(),
                  style: AppTypography.poppins(fontSize: 14, color: CupertinoColors.destructiveRed, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showCustomModal(
      context: context,
      builder: (ctx) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.square_arrow_left,
                    size: 28, color: CupertinoColors.destructiveRed),
              ),
              const SizedBox(height: 16),
              Text('logout'.tr(),
                  style: AppTypography.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ctx.primaryTextColor)),
              const SizedBox(height: 8),
              Text('are_you_sure_logout'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(
                      fontSize: 13, color: ctx.secondaryTextColor)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPointer(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.systemGrey5,
                            border: Border.all(
                                color: CupertinoColors.systemGrey4),
                          ),
                          child: const Icon(CupertinoIcons.xmark,
                              size: 22, color: CupertinoColors.systemGrey),
                        ),
                        const SizedBox(height: 6),
                        Text('no'.tr(),
                            style: AppTypography.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ctx.secondaryTextColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                CustomPointer(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(authProvider.notifier).logout();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.destructiveRed,
                          ),
                          child: const Icon(CupertinoIcons.check_mark,
                              size: 22, color: CupertinoColors.white),
                        ),
                        const SizedBox(height: 6),
                        Text('yes'.tr(),
                            style: AppTypography.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.destructiveRed)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  String _getPageTitle() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/dashboard') return 'dashboard'.tr();
    if (location.startsWith('/products')) return 'products'.tr();
    if (location.startsWith('/categories')) return 'categories'.tr();
    if (location.startsWith('/suppliers')) return 'suppliers'.tr();
    if (location.startsWith('/customers')) return 'customers'.tr();
    if (location.startsWith('/inventory')) return 'inventory'.tr();
    if (location.startsWith('/purchases')) return 'purchases'.tr();
    if (location.startsWith('/sales')) return 'sales'.tr();
    if (location.startsWith('/reports')) return 'reports'.tr();
    if (location.startsWith('/settings')) return 'settings'.tr();
    if (location.startsWith('/audit-logs')) return 'audit_logs'.tr();
    return 'SahibZ';
  }
}
