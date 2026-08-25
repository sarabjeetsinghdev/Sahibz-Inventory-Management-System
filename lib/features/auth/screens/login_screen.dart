// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/features/auth/providers/auth_provider.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingsState = ref.watch(settingsProvider);
    final isDark = settingsState.settings.isDarkTheme;

    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final bg = brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);
    final surface = brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : CupertinoColors.white;
    final textColor = brightness == Brightness.dark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);
    final secondary = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bg,
        middle: Text('login'.tr()),
        trailing: CustomPointer(
          onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isDark
                  ? CupertinoIcons.sun_max
                  : CupertinoIcons.moon,
              size: 22,
              color: textColor,
            ),
          ),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: isDark
                      ? CupertinoColors.black.withOpacity(0.5)
                      : CupertinoColors.black,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(CupertinoIcons.square_list,
                      color: CupertinoColors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text('SAHIBZ',
                    style: AppTypography.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 4),
                Text('Inventory Management System',
                    style:
                        AppTypography.poppins(fontSize: 14, color: secondary)),
                const SizedBox(height: 32),
                CupertinoTextField(
                  controller: _usernameController,
                  placeholder: 'Username',
                  placeholderStyle: const TextStyle(
                      fontSize: 15.0, color: CupertinoColors.placeholderText),
                  style: const TextStyle(fontSize: 17.0, letterSpacing: 1.1),
                  padding: const EdgeInsets.all(16),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.person,
                        size: 20, color: CupertinoColors.systemGrey),
                  ),
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'password'.tr(),
                  placeholderStyle: const TextStyle(
                      fontSize: 15.0, color: CupertinoColors.placeholderText),
                  style: const TextStyle(fontSize: 17.0, letterSpacing: 1.1),
                  obscureText: _obscured,
                  padding: const EdgeInsets.all(16),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.lock,
                        size: 20, color: CupertinoColors.systemGrey),
                  ),
                  suffix: CustomPointer(
                      child: GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        _obscured
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 20,
                        color: secondary,
                      ),
                    ),
                  )),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(authState.error!,
                      style: AppTypography.poppins(
                          color: CupertinoColors.destructiveRed, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                CustomPointer(
                  child: CupertinoButton.filled(
                    sizeStyle: CupertinoButtonSize.medium,
                    borderRadius: BorderRadius.circular(12.0),
                    onPressed: _submit,
                    child: Text('sign_in'.tr(),
                        style: AppTypography.poppins(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
