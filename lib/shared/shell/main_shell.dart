// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/features/auth/providers/auth_provider.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
// import 'package:sahibz_inventory/shared/custom_modal.dart';
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
                    Expanded(child: _buildNavList(navItemColor, context.primaryTextColor, context.secondaryTextColor, context.borderColor, brightness, isDesktop)),
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
      bool isDesktop) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _sectionLabel('MAIN', secondaryText),
        _navItem(CupertinoIcons.house_alt, 'dashboard'.tr(), '/dashboard', primary, text, brightness),
        const SizedBox(height: 6.0),
        _sectionLabel('INVENTORY', secondaryText),
        _navItem(CupertinoIcons.tray_2, 'products'.tr(), '/products', primary, text, brightness),
        _navItem(CupertinoIcons.folder, 'categories'.tr(), '/categories', primary, text, brightness),
        _navItem(CupertinoIcons.square_list_fill, 'inventory'.tr(), '/inventory', primary, text, brightness),
        const SizedBox(height: 6.0),
        _sectionLabel('TRANSACTIONS', secondaryText),
        _navItem(CupertinoIcons.cart, 'purchases'.tr(), '/purchases', primary, text, brightness),
        _navItem(CupertinoIcons.money_dollar, 'sales'.tr(), '/sales', primary, text, brightness),
        const SizedBox(height: 6.0),
        _sectionLabel('RELATIONS', secondaryText),
        _navItem(CupertinoIcons.briefcase, 'suppliers'.tr(), '/suppliers', primary, text, brightness),
        _navItem(CupertinoIcons.person_3, 'customers'.tr(), '/customers', primary, text, brightness),
        const SizedBox(height: 6.0),
        _sectionLabel('MANAGEMENT', secondaryText),
        _navItem(CupertinoIcons.chart_bar, 'reports'.tr(), '/reports', primary, text, brightness),
        _navItem(CupertinoIcons.shield, 'audit_logs'.tr(), '/audit-logs', primary, text, brightness),
        _navItem(CupertinoIcons.gear, 'settings'.tr(), '/settings', primary, text, brightness),
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
    final isActive = _isActiveRoute(route);
    final bg = isActive
        ? (brightness == Brightness.dark ? primary.withOpacity(0.2) : primary.withOpacity(0.08))
        : CupertinoColors.transparent;
    final fg = isActive ? primary : text;
    return CustomPointer(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.poppins(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: fg)),
          ],
        ),
      ),
    );
  }

  bool _isActiveRoute(String route) {
    final location = GoRouterState.of(context).matchedLocation;
    if (route == '/dashboard') return location == '/dashboard';
    return location.startsWith(route);
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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('logout'.tr()),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text('logout'.tr()),
          ),
        ],
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
