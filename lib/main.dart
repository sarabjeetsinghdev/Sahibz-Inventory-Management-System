import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/routes/app_router.dart';
import 'package:sahibz_inventory/themes/app_theme.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/features/updates/providers/update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
          Locale('pa', 'IN'),
          Locale('tl', 'PH'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        saveLocale: true,
        useOnlyLangCode: true,
        child: const SahibZApp(),
      ),
    ),
  );
}

class SahibZApp extends ConsumerStatefulWidget {
  const SahibZApp({super.key});

  @override
  ConsumerState<SahibZApp> createState() => _SahibZAppState();
}

class _SahibZAppState extends ConsumerState<SahibZApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).load();
      ref.read(updateProvider.notifier).init();
      ref.read(updateProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final settingsState = ref.watch(settingsProvider);

    final isDark = settingsState.settings.theme == 'dark';

    return CupertinoApp.router(
      title: 'app_name'.tr(),
      theme: AppTheme.themeFor(
        brightness: isDark ? Brightness.dark : Brightness.light,
        accent: AppTheme.colorFromHex(settingsState.settings.accentColor),
      ),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
