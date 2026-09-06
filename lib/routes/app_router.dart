import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/features/auth/screens/login_screen.dart';
import 'package:sahibz_inventory/features/auth/providers/auth_provider.dart';
import 'package:sahibz_inventory/features/auth/widgets/auth_guard.dart';
import 'package:sahibz_inventory/features/dashboard/screens/dashboard_screen.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';
import 'package:sahibz_inventory/features/products/screens/product_list_screen.dart';
import 'package:sahibz_inventory/features/products/screens/product_form_screen.dart';
import 'package:sahibz_inventory/features/categories/screens/category_list_screen.dart';
import 'package:sahibz_inventory/features/suppliers/screens/supplier_list_screen.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';
import 'package:sahibz_inventory/features/suppliers/screens/supplier_form_screen.dart';
import 'package:sahibz_inventory/features/customers/models/customer_model.dart';
import 'package:sahibz_inventory/features/customers/screens/customer_list_screen.dart';
import 'package:sahibz_inventory/features/customers/screens/customer_form_screen.dart';
import 'package:sahibz_inventory/features/inventory/screens/inventory_list_screen.dart';
import 'package:sahibz_inventory/features/inventory/screens/inventory_transaction_form.dart';
import 'package:sahibz_inventory/features/purchases/screens/purchase_list_screen.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/purchases/screens/purchase_form_screen.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/features/sales/screens/sale_list_screen.dart';
import 'package:sahibz_inventory/features/sales/screens/sale_form_screen.dart';
import 'package:sahibz_inventory/features/reports/screens/report_list_screen.dart';
import 'package:sahibz_inventory/features/reports/screens/report_viewer_screen.dart';
import 'package:sahibz_inventory/features/settings/screens/settings_screen.dart';
import 'package:sahibz_inventory/features/settings/screens/feature_flags_screen.dart';
import 'package:sahibz_inventory/features/audit_logs/screens/audit_log_screen.dart';
import 'package:sahibz_inventory/shared/shell/main_shell.dart';
import 'package:sahibz_inventory/core/feature_flags.dart';

Page<void> _formPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refreshNotifier.value++);
  ref.listen(featureFlagsProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(() => refreshNotifier.dispose());

  String _featureForLocation(String loc) {
    if (loc == '/dashboard') return 'dashboard';
    if (loc.startsWith('/products')) return 'products';
    if (loc.startsWith('/categories')) return 'categories';
    if (loc.startsWith('/inventory')) return 'inventory';
    if (loc.startsWith('/purchases')) return 'purchases';
    if (loc.startsWith('/sales')) return 'sales';
    if (loc.startsWith('/suppliers')) return 'suppliers';
    if (loc.startsWith('/customers')) return 'customers';
    if (loc.startsWith('/reports')) return 'reports';
    if (loc.startsWith('/audit-logs')) return 'audit_logs';
    if (loc.startsWith('/settings')) return 'settings';
    return '';
  }

  String _firstEnabledRoute(FeatureFlags f) {
    if (f.dashboard) return '/dashboard';
    if (f.products) return '/products';
    if (f.categories) return '/categories';
    if (f.inventory) return '/inventory';
    if (f.purchases) return '/purchases';
    if (f.sales) return '/sales';
    if (f.suppliers) return '/suppliers';
    if (f.customers) return '/customers';
    if (f.reports) return '/reports';
    if (f.auditLogs) return '/audit-logs';
    return '/settings';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final flags = ref.read(featureFlagsProvider);
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return _firstEnabledRoute(flags);
      }
      if (isLoggedIn) {
        final feature = _featureForLocation(state.matchedLocation);
        if (feature.isNotEmpty && !flags.isEnabled(feature)) {
          return _firstEnabledRoute(flags);
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AuthGuard(child: MainShell(child: child)),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'productAdd',
                pageBuilder: (context, state) => _formPage(state, ProductFormScreen(product: state.extra as ProductModel?)),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoryListScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            builder: (context, state) => const SupplierListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'supplierAdd',
                pageBuilder: (context, state) => _formPage(state, SupplierFormScreen(supplier: state.extra as SupplierModel?)),
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'customerAdd',
                pageBuilder: (context, state) => _formPage(state, CustomerFormScreen(customer: state.extra as CustomerModel?)),
              ),
            ],
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryListScreen(),
            routes: [
              GoRoute(
                path: 'transaction',
                name: 'inventoryTransaction',
                pageBuilder: (context, state) => _formPage(state, const InventoryTransactionForm()),
              ),
            ],
          ),
          GoRoute(
            path: '/purchases',
            name: 'purchases',
            builder: (context, state) => const PurchaseListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'purchaseAdd',
                pageBuilder: (context, state) => _formPage(state, PurchaseFormScreen(purchase: state.extra as PurchaseModel?)),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) => const SaleListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'saleAdd',
                pageBuilder: (context, state) => _formPage(state, SaleFormScreen(sale: state.extra as SaleModel?)),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportListScreen(),
            routes: [
              GoRoute(
                path: 'viewer',
                name: 'reportViewer',
                builder: (context, state) => ReportViewerScreen(
                  config: state.extra as ReportTypeConfig,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'features',
                name: 'featureFlags',
                builder: (context, state) => const FeatureFlagsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/audit-logs',
            name: 'auditLogs',
            builder: (context, state) => const AuditLogScreen(),
          ),
        ],
      ),
    ],
  );
});
