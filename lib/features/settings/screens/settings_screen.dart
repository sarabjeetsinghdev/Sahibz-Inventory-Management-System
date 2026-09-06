import 'package:sahibz_inventory/features/settings/repositories/settings_repository.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/features/updates/providers/update_provider.dart';
import 'package:sahibz_inventory/features/settings/models/settings_model.dart';
import 'package:sahibz_inventory/features/updates/screens/update_dialog.dart';
import 'package:sahibz_inventory/features/auth/providers/auth_provider.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/themes/app_theme.dart';
import 'package:sahibz_inventory/core/feature_flags.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _tinController = TextEditingController();
  final _currencyController = TextEditingController();
  final _symbolController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _selectedDateFormat = 'dd/MM/yyyy';
  String _selectedTimeFormat = 'HH:mm';
  String _selectedLanguage = 'en';
  String _selectedTheme = 'light';
  String _selectedAccentColor = '#0D9488';
  String _selectedBackupFreq = 'daily';
  bool _autoBackup = false;
  bool _logToFile = false;
  String? _logoPath;

  bool _isInitialized = false;

  static const _dateFormats = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
    'dd.MM.yyyy'
  ];
  static const _timeFormats = ['HH:mm', 'hh:mm a', 'HH:mm:ss'];
  static const _languages = [
    ('en', 'English'),
    ('hi', 'Hindi'),
    ('pa', 'Punjabi'),
    ('tl', 'Tagalog'),
  ];
  static const _backupFrequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
  ];
  static const _accentColors = [
    '#0D9488',
    '#2563EB',
    '#0EA5E9',
    '#059669',
    '#7C3AED',
    '#EA580C',
    '#DB2777',
    '#DC2626',
    '#4F46E5',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tinController.dispose();
    _currencyController.dispose();
    _symbolController.dispose();
    _taxRateController.dispose();
    _thresholdController.dispose();
    _oldPasswordController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _initFromSettings(AppSettings s) {
    _nameController.text = s.companyName;
    _phoneController.text = s.companyPhone;
    _emailController.text = s.companyEmail;
    _addressController.text = s.companyAddress;
    _tinController.text = s.companyTin;
    _currencyController.text = s.currency;
    _symbolController.text = s.currencySymbol;
    _taxRateController.text = s.taxRate.toString();
    _thresholdController.text = s.lowStockThreshold.toString();
    _selectedDateFormat = s.dateFormat;
    _selectedTimeFormat = s.timeFormat;
    _selectedLanguage = s.language;
    _selectedTheme = s.theme;
    _selectedAccentColor = s.accentColor;
    _autoBackup = s.autoBackup;
    _selectedBackupFreq = s.backupFrequency;
    _logToFile = s.logToFile;
    _logoPath = s.companyLogo;
  }

  AppSettings _buildSettings() {
    return AppSettings(
      companyName: _nameController.text,
      companyPhone: _phoneController.text,
      companyEmail: _emailController.text,
      companyAddress: _addressController.text,
      companyTin: _tinController.text,
      companyLogo: _logoPath,
      currency: _currencyController.text.isNotEmpty
          ? _currencyController.text
          : 'PHP',
      currencySymbol:
          _symbolController.text.isNotEmpty ? _symbolController.text : '\u20B1',
      taxRate: double.tryParse(_taxRateController.text) ?? 18.0,
      dateFormat: _selectedDateFormat,
      timeFormat: _selectedTimeFormat,
      language: _selectedLanguage,
      theme: _selectedTheme,
      accentColor: _selectedAccentColor,
      lowStockThreshold: int.tryParse(_thresholdController.text) ?? 10,
      autoBackup: _autoBackup,
      backupFrequency: _selectedBackupFreq,
      logToFile: _logToFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    if (!state.isLoaded && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.load());
    }

    if (state.isLoaded && !_isInitialized) {
      _isInitialized = true;
      _initFromSettings(state.settings);
    }

    ref.listen<SettingsState>(settingsProvider, (SettingsState? prev, SettingsState next) {
      if (next.isLoaded && !next.isSaving && (prev == null || prev.settings != next.settings)) {
        _initFromSettings(next.settings);
      }
    });

    final updateState = ref.watch(updateProvider);
    if (updateState.currentVersion == 'unknown') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(updateProvider.notifier).init();
      });
    }
    ref.listen<UpdateState>(updateProvider, (UpdateState? prev, UpdateState next) {
      if (prev != null && prev.status != UpdateStatus.available &&
          next.status == UpdateStatus.available && mounted) {
        showUpdateDialog(context);
      }
      if (prev != null && prev.status == UpdateStatus.checking &&
          next.status == UpdateStatus.upToDate && mounted) {
        showUpdateDialog(context);
      }
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('settings'.tr()),
        trailing: state.isSaving
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20, height: 20, child: CupertinoActivityIndicator()),
              )
            : null,
      ),
      child: state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : state.error != null
              ? _buildError(context, state.error!)
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildSectionHeader('application'.tr()),
                    _buildCompanyTile(),
                    _buildCurrencyTile(),
                    _buildRegionalTile(),
                    _buildAppearanceTile(),
                    _buildBackupTile(),
                    _buildSecurityTile(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('system'.tr()),
                    _buildUpdatesTile(),
                    _buildErrorLogTile(),
                    _buildFeatureFlagsTile(),
                    const SizedBox(height: 8),
                    _buildSelfDestructTile(),
                  ],
                ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 64, color: CupertinoColors.destructiveRed),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => ref.read(settingsProvider.notifier).load(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // ========== TILE BUILDERS ==========

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(title,
          style: AppTypography.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return CustomPointer(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: context.isDarkTheme
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF000000).withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.poppins(
                          fontSize: 12, color: context.secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            trailing ??
                Icon(CupertinoIcons.chevron_forward, size: 20, color: context.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyTile() {
    return _buildCardTile(
      icon: CupertinoIcons.building_2_fill,
      title: 'company_profile'.tr(),
      subtitle: _nameController.text.isNotEmpty ? _nameController.text : 'not_set'.tr(),
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showCompanyDialog,
    );
  }

  Widget _buildCurrencyTile() {
    final currency = _currencyController.text.isNotEmpty ? _currencyController.text : 'PHP';
    final symbol = _symbolController.text.isNotEmpty ? _symbolController.text : '\u20B1';
    final tax = _taxRateController.text.isNotEmpty ? _taxRateController.text : '18';
    return _buildCardTile(
      icon: CupertinoIcons.money_dollar,
      title: 'currency_vat'.tr(),
      subtitle: '$currency, $symbol, $tax%',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showCurrencyDialog,
    );
  }

  Widget _buildRegionalTile() {
    final lang = _languages.firstWhere((l) => l.$1 == _selectedLanguage).$2;
    return _buildCardTile(
      icon: CupertinoIcons.globe,
      title: 'regional'.tr(),
      subtitle: '$_selectedDateFormat, $_selectedTimeFormat, $lang',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showRegionalDialog,
    );
  }

  Widget _buildAppearanceTile() {
    return _buildCardTile(
      icon: CupertinoIcons.paintbrush,
      title: 'appearance'.tr(),
      subtitle:
          '${_selectedTheme == 'light' ? 'light'.tr() : 'Dark'} \u2022 $_selectedAccentColor',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showAppearanceDialog,
    );
  }

  Widget _buildBackupTile() {
    final freq = _backupFrequencies.firstWhere((f) => f.$1 == _selectedBackupFreq).$2;
    final threshold = _thresholdController.text.isNotEmpty ? _thresholdController.text : '10';
    return _buildCardTile(
      icon: CupertinoIcons.cloud,
      title: 'backup'.tr(),
      subtitle: 'Auto: ${_autoBackup ? "On" : "Off"}, $freq, Threshold: $threshold',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showBackupDialog,
    );
  }

  Widget _buildSecurityTile() {
    return _buildCardTile(
      icon: CupertinoIcons.lock_fill,
      title: 'security'.tr(),
      subtitle: 'change_username'.tr(),
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: _showSecurityDialog,
    );
  }

  Widget _buildUpdatesTile() {
    final updateState = ref.watch(updateProvider);
    final isBusy = updateState.status == UpdateStatus.checking ||
        updateState.status == UpdateStatus.downloading;
    final isError = updateState.status == UpdateStatus.error;

    return _buildCardTile(
      icon: CupertinoIcons.cloud_download,
      title: 'updates'.tr(),
      subtitle: '${'version_label'.tr()} ${updateState.currentVersion}',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: isBusy ? null : () => ref.read(updateProvider.notifier).checkForUpdate(),
      trailing: isBusy
          ? const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator())
          : CustomPointer(
              onTap: () => ref.read(updateProvider.notifier).checkForUpdate(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isError ? 'retry'.tr() : 'check'.tr(),
                    style: AppTypography.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              ),
            ),
    );
  }

  Widget _buildErrorLogTile() {
    return _buildCardTile(
      icon: CupertinoIcons.doc_text,
      title: 'error_logging'.tr(),
      subtitle: _logToFile ? 'logs_enabled'.tr() : 'logs_disabled'.tr(),
      iconColor: CupertinoTheme.of(context).primaryColor,
      trailing: CupertinoSwitch(
        value: _logToFile,
        onChanged: (v) {
          setState(() => _logToFile = v);
          _saveErrorLog();
        },
      ),
    );
  }

  Future<void> _saveErrorLog() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted && error != null) {
      _showResult(error);
    }
  }

  Widget _buildFeatureFlagsTile() {
    final flags = ref.watch(featureFlagsProvider);
    final enabled = FeatureFlags.allKeys.where((k) => flags.isEnabled(k)).length;
    return _buildCardTile(
      icon: CupertinoIcons.eye,
      title: 'Features',
      subtitle: '$enabled of ${FeatureFlags.allKeys.length} enabled',
      iconColor: CupertinoTheme.of(context).primaryColor,
      onTap: () => context.push('/settings/features'),
    );
  }

  Widget _buildSelfDestructTile() {
    return _buildCardTile(
      icon: CupertinoIcons.trash_fill,
      title: 'reset_app'.tr(),
      subtitle: 'delete_data_warning'.tr(),
      iconColor: CupertinoColors.destructiveRed,
      onTap: _showSelfDestructDialog,
    );
  }

  void _showSelfDestructDialog() {
    final passwordCtrl = TextEditingController();

    showCustomModal(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 48, color: CupertinoColors.destructiveRed),
              const SizedBox(height: 16),
              Text('reset_app'.tr(), style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('enter_password_confirm'.tr(),
                  style: AppTypography.poppins(fontSize: 14, color: context.secondaryTextColor),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: passwordCtrl, placeholder: 'password'.tr(),
                obscureText: true,
                prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.lock_fill, size: 20)),
                decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: Text('confirm'.tr()),
                  onPressed: () async {
                    final repo = ref.read(settingsRepositoryProvider);
                    final storedPwResult = await repo.get('password');
                    final storedPw = storedPwResult.value ?? 'admin';
                    if (passwordCtrl.text != storedPw) {
                      if (ctx.mounted) {
                        showCupertinoDialog(
                          context: ctx,
                          builder: (c) => CupertinoAlertDialog(
                            title: Text('error'.tr()),
                            content: Text('incorrect_password'.tr()),
                            actions: [CupertinoDialogAction(child: Text('ok'.tr()), onPressed: () => Navigator.pop(c))],
                          ),
                        );
                      }
                      return;
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (!mounted) return;
                    _showDestructConfirm();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDestructConfirm() {
    showCustomModal(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.trash_fill, size: 48, color: CupertinoColors.destructiveRed),
              const SizedBox(height: 16),
              Text('reset_app'.tr(), style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('delete_data_confirmation'.tr(),
                  style: AppTypography.poppins(fontSize: 14, color: context.secondaryTextColor),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: Text('yes_delete'.tr()),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    await _executeDestruct();
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CustomPointer(
                  child: CupertinoButton.filled(
                    color: CupertinoColors.systemRed,
                    child: Text('cancel'.tr()),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeDestruct() async {
    final db = ref.read(databaseProvider);
    await db.resetDatabase();
    ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('success'.tr()),
        content: Text('reset_complete'.tr()),
        actions: [
          CupertinoDialogAction(
            child: Text('ok'.tr()),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ========== DIALOG METHODS ==========

  void _showCompanyDialog() {
    final nameCtrl = TextEditingController(text: _nameController.text);
    final phoneCtrl = TextEditingController(text: _phoneController.text);
    final emailCtrl = TextEditingController(text: _emailController.text);
    final addressCtrl = TextEditingController(text: _addressController.text);
    final tinCtrl = TextEditingController(text: _tinController.text);
    String? logoPath = _logoPath;

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final prim = CupertinoTheme.of(context).primaryColor;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('company_profile'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Center(child: CustomPointer(child: GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                            source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
                        if (file != null) {
                          setDialogState(() => logoPath = file.path);
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: prim.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                        image: logoPath != null
                            ? DecorationImage(image: FileImage(File(logoPath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: logoPath == null
                          ? Icon(CupertinoIcons.photo, size: 28, color: prim)
                          : null,
                    ),
                  ))),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: nameCtrl, placeholder: 'company_name'.tr(),
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.building_2_fill, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: phoneCtrl, placeholder: 'phone'.tr(),
                    keyboardType: TextInputType.phone,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.phone, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: emailCtrl, placeholder: 'email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.mail, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: addressCtrl, placeholder: 'address'.tr(),
                    maxLines: 3,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.location, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: tinCtrl, placeholder: 'TIN Number (VAT Reg)',
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.doc_plaintext, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _nameController.text = nameCtrl.text;
                          _phoneController.text = phoneCtrl.text;
                          _emailController.text = emailCtrl.text;
                          _addressController.text = addressCtrl.text;
                          _tinController.text = tinCtrl.text;
                          _logoPath = logoPath;
                        });
                        _saveCompanyProfile();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCurrencyDialog() {
    final currencyCtrl = TextEditingController(text: _currencyController.text);
    final symbolCtrl = TextEditingController(text: _symbolController.text);
    final taxCtrl = TextEditingController(text: _taxRateController.text);

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('currency_vat'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  CupertinoTextField(
                    controller: currencyCtrl, placeholder: 'Currency Code (e.g., INR, USD)',
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.money_dollar, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: symbolCtrl, placeholder: 'Currency Symbol (e.g., \u20B1, \$)',
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.money_dollar, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: taxCtrl, placeholder: 'VAT Rate (%)',
                    keyboardType: TextInputType.number,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.percent, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _currencyController.text = currencyCtrl.text;
                          _symbolController.text = symbolCtrl.text;
                          _taxRateController.text = taxCtrl.text;
                        });
                        _saveCurrencyTax();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRegionalDialog() {
    String dateFormat = _selectedDateFormat;
    String timeFormat = _selectedTimeFormat;
    String language = _selectedLanguage;

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('regional'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                   CupertinoListTile(
                    title: Text('date_format'.tr()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dateFormat),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                    onTap: () => _showPicker(
                      context,
                      dateFormat,
                      _dateFormats,
                      (v) => setDialogState(() => dateFormat = v),
                      labels: _dateFormats.map((e) => '$e (${DateFormat(e).format(DateTime.now())})').toList(),
                    ),
                  ),
                  CupertinoListTile(
                    title: Text('time_format'.tr()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(timeFormat),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                    onTap: () => _showPicker(
                      context,
                      timeFormat,
                      _timeFormats,
                      (v) => setDialogState(() => timeFormat = v),
                      labels: _timeFormats.map((e) => '$e (${DateFormat(e).format(DateTime.now())})').toList(),
                    ),
                  ),
                  CupertinoListTile(
                    title: Text('language'.tr()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_languages.firstWhere((l) => l.$1 == language).$2),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                    onTap: () => _showPicker(
                      context,
                      language,
                      _languages.map((l) => l.$1).toList(),
                      (v) => setDialogState(() => language = v),
                      labels: _languages.map((l) => l.$2).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _selectedDateFormat = dateFormat;
                          _selectedTimeFormat = timeFormat;
                          _selectedLanguage = language;
                        });
                        final localeMap = {'en': const Locale('en', 'US'), 'hi': const Locale('hi', 'IN'), 'pa': const Locale('pa', 'IN'), 'tl': const Locale('tl', 'PH')};
                        context.setLocale(localeMap[language] ?? const Locale('en', 'US'));
                        _saveRegional();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAppearanceDialog() {
    String theme = _selectedTheme;
    String accent = _selectedAccentColor;

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('appearance'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  CupertinoListTile(
                    title: Text('theme'.tr()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(theme == 'light' ? 'light'.tr() : 'dark'.tr()),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                    onTap: () => _showPicker(
                      context,
                      theme,
                      ['light', 'dark'],
                      (v) => setDialogState(() => theme = v),
                      labels: ['light'.tr(), 'dark'.tr()],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('accent_color'.tr(),
                        style: AppTypography.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.secondaryTextColor)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _accentColors.map((c) {
                      final isSelected = c == accent;
                      return CustomPointer(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => accent = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.colorFromHex(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? context.primaryTextColor
                                    : context.borderColor,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(CupertinoIcons.checkmark_alt,
                                    size: 18, color: CupertinoColors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _selectedTheme = theme;
                          _selectedAccentColor = accent;
                        });
                        _saveAppearance();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBackupDialog() {
    bool autoBackup = _autoBackup;
    String backupFreq = _selectedBackupFreq;
    final thresholdCtrl = TextEditingController(text: _thresholdController.text);

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('backup'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  CupertinoListTile(
                    title: const Text('Auto Backup'),
                    subtitle: const Text('Automatically backup data on schedule'),
                    trailing: CupertinoSwitch(
                      value: autoBackup,
                      onChanged: (v) => setDialogState(() => autoBackup = v),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Backup Frequency'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_backupFrequencies.firstWhere((f) => f.$1 == backupFreq).$2),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                    onTap: () => _showPicker(
                      context,
                      backupFreq,
                      _backupFrequencies.map((f) => f.$1).toList(),
                      (v) => setDialogState(() => backupFreq = v),
                      labels: _backupFrequencies.map((f) => f.$2).toList(),
                    ),
                  ),
                  CupertinoTextField(
                    controller: thresholdCtrl, placeholder: 'low_stock_threshold'.tr(),
                    keyboardType: TextInputType.number,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.square_list_fill, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _autoBackup = autoBackup;
                          _selectedBackupFreq = backupFreq;
                          _thresholdController.text = thresholdCtrl.text;
                        });
                        _saveBackup();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSecurityDialog() {
    final oldPwdCtrl = TextEditingController();
    final newUserCtrl = TextEditingController(text: _newUsernameController.text);
    final newPwdCtrl = TextEditingController();

    showCustomModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('security'.tr(),
                      style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  CupertinoTextField(
                    controller: oldPwdCtrl, placeholder: 'current_password'.tr(),
                    obscureText: true,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.lock_fill, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: newUserCtrl, placeholder: 'new_username'.tr(),
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.person_fill, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: newPwdCtrl, placeholder: 'new_password'.tr(),
                    obscureText: true,
                    prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.lock_fill, size: 20)),
                    decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: Text('save'.tr()),
                      onPressed: () {
                        setState(() {
                          _oldPasswordController.text = oldPwdCtrl.text;
                          _newUsernameController.text = newUserCtrl.text;
                          _newPasswordController.text = newPwdCtrl.text;
                        });
                        _saveSecurity();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPicker(
    BuildContext context,
    String currentValue,
    List<String> values,
    ValueChanged<String> onChanged, {
    List<String>? labels,
  }) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: values,
        labels: labels,
        initialValue: currentValue,
        onSelected: (value) => onChanged(value),
      ),
    );
  }

  Future<void> _saveCompanyProfile() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted) {
      _showResult(error ?? 'Company profile saved successfully');
    }
  }

  Future<void> _saveCurrencyTax() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted) {
      _showResult(error ?? 'Currency & VAT settings saved successfully');
    }
  }

  Future<void> _saveRegional() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted) {
      _showResult(error ?? 'Regional settings saved successfully');
    }
  }

  Future<void> _saveAppearance() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted) {
      _showResult(error ?? 'Appearance settings saved successfully');
    }
  }

  Future<void> _saveBackup() async {
    final settings = _buildSettings();
    final error = await ref.read(settingsProvider.notifier).saveAll(settings);
    if (mounted) {
      _showResult(error ?? 'Backup settings saved successfully');
    }
  }

  Future<void> _saveSecurity() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newUsername = _newUsernameController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    if (oldPassword.isEmpty || newUsername.isEmpty || newPassword.isEmpty) {
      _showResult('All fields are required');
      return;
    }
    final error = await ref.read(authProvider.notifier).changeCredentials(oldPassword, newUsername, newPassword);
    if (mounted) {
      _showResult(error ?? 'Credentials updated successfully');
    }
    _oldPasswordController.clear();
    _newUsernameController.clear();
    _newPasswordController.clear();
  }

  void _showResult(String msg) {
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('success'.tr(),
                style: AppTypography.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppTypography.poppins(
                    fontSize: 14, color: context.secondaryTextColor)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('ok'.tr()),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
