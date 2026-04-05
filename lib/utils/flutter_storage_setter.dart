// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flutterStorageProvider = Provider<FlutterStorageSetter>(
  (ref) => FlutterStorageSetter(),
);

class FlutterStorageSetter {
  /// Secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String dateTimeParserKey = 'dateTimeParser';

  /// Organisation name key
  static const String organisationNameKey = 'organisationName';

  /// Username key
  static const String usernameKey = 'username';

  /// Password key
  static const String passwordKey = 'password';

  /// Security question key
  static const String securityQuestionKey = 'securityQuestion';

  /// Security answer key
  static const String securityAnswerKey = 'securityAnswer';

  /// Default organisation name
  static const String defaultOrganisationName = 'Not Set';

  /// Default username
  static const String defaultUsername = 'admin';

  /// Default password
  static const String defaultPassword = '123456';

  FlutterStorageSetter() {
    _initializeDefaults();
  }

  /// Hash password
  ///
  /// Returns the hashed password.
  String hashPassword(String password) {
    // Encode the password to UTF-8 bytes
    final utf8Bytes = utf8.encode(password);
    // Hash the password
    final hashedPassword = sha512256.convert(utf8Bytes).toString();
    return hashedPassword;
  }

  /// Initialize default values if storage is empty
  Future<void> _initializeDefaults() async {
    // Check if organisation name is empty and set a default
    if (await _secureStorage.read(key: organisationNameKey) == null) {
      await _secureStorage.write(
        key: organisationNameKey,
        value: defaultOrganisationName,
      );
    }

    // Check if datetime parser is empty and set a default
    if (await _secureStorage.read(key: dateTimeParserKey) == null) {
      await _secureStorage.write(
        key: dateTimeParserKey,
        value: DateTimeParserEnum.dmyt12.value,
      );
    }

    // Check if username is empty and set a default
    if (await _secureStorage.read(key: usernameKey) == null) {
      await _secureStorage.write(key: usernameKey, value: defaultUsername);
    }

    // Check if password is empty and set a default
    if (await _secureStorage.read(key: passwordKey) == null) {
      await _secureStorage.write(
        key: passwordKey,
        value: hashPassword(defaultPassword),
      );
    }
  }

  /// Get organisation name
  ///
  /// Returns the organisation name if set, otherwise null.
  Future<String?> getOrganisationName() async {
    return await _secureStorage.read(key: organisationNameKey);
  }

  /// Set organisation name
  ///
  /// Sets the organisation name in secure storage.
  Future<void> setOrganisationName(String name) =>
      _secureStorage.write(key: organisationNameKey, value: name);

  /// Get datetime parser enum string
  ///
  /// Returns the datetime parser enum string if set, otherwise null.
  Future<String?> getDateTimeParserEnumString() =>
      _secureStorage.read(key: dateTimeParserKey);

  /// Get user username
  ///
  /// Returns the username if set, otherwise null.
  ///
  Future<String?> getUsername() async {
    return await _secureStorage.read(key: usernameKey);
  }

  /// Set user username
  ///
  /// Sets the username in secure storage.
  Future<void> setUsername(String username) =>
      _secureStorage.write(key: usernameKey, value: username);

  /// Get password
  ///
  /// Returns the hashed password if set, otherwise null.
  Future<String?> getPassword() async {
    // Get the hashed password from secure storage
    final hashedPassword = await _secureStorage.read(key: passwordKey);
    if (hashedPassword == null) {
      return null;
    }
    return hashedPassword;
  }

  /// Set password
  ///
  /// Sets the hashed password in secure storage.
  Future<void> setPassword(String password) async {
    // Hash the password
    final hashedPassword = hashPassword(password);
    // Store the hashed password in secure storage
    await _secureStorage.write(key: passwordKey, value: hashedPassword);
  }

  /// Get Security Question
  ///
  /// Returns the security question if set, otherwise null.
  Future<String?> getSecurityQuestion() async {
    return await _secureStorage.read(key: securityQuestionKey);
  }

  /// Set Security Question
  ///
  /// Sets the security question in secure storage.
  Future<void> setSecurityQuestion(String question) =>
      _secureStorage.write(key: securityQuestionKey, value: question);

  /// Get Security Answer
  ///
  /// Returns the security answer if set, otherwise null.
  Future<String?> getSecurityAnswer() async {
    return await _secureStorage.read(key: securityAnswerKey);
  }

  /// Set Security Answer
  ///
  /// Sets the security answer in secure storage.
  Future<void> setSecurityAnswer(String answer) =>
      _secureStorage.write(key: securityAnswerKey, value: answer);

  /// Get datetime parser enum
  ///
  /// Returns the datetime parser enum if set, otherwise null.
  Future<DateTimeParserEnum?> getDateTimeParserStorageEnum() async {
    final stored = await getDateTimeParserEnumString();
    if (stored == null) {
      return null;
    }
    return DateTimeParserEnum.values.cast<DateTimeParserEnum?>().firstWhere(
      (e) => e!.value == stored,
      orElse: () => null,
    );
  }

  /// Set datetime parser enum string
  ///
  /// Sets the datetime parser enum string in secure storage.
  ///
  /// [parser] - The datetime parser enum string to set.
  ///
  /// Returns a future that completes when the operation is complete.
  Future<void> setDateTimeParser(String parser) =>
      _secureStorage.write(key: dateTimeParserKey, value: parser);

  /// Create user
  ///
  /// Creates a new user in secure storage.
  ///
  /// [context] - The build context to use for the error dialog.
  /// [organisationName] - The organisation name to set.
  /// [username] - The username to set.
  /// [password] - The password to set.
  /// [securityQuestion] - The security question to set.
  /// [securityAnswer] - The security answer to set.
  ///
  /// Returns a future that completes when the operation is complete.
  Future<void> createUser({
    required BuildContext context,
    required String organisationName,
    required String username,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      await clearUser();
      await setDateTimeParser(DateTimeParserEnum.wcdmyt12.value);
      await setOrganisationName(organisationName);
      await setUsername(username);
      await setPassword(password);
      await setSecurityQuestion(securityQuestion);
      await setSecurityAnswer(securityAnswer);
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  Future<void> clearUser() async {
    await _secureStorage.deleteAll();
    await DatabaseHelper.instance.deleteDb();
    _initializeDefaults();
  }

  Map<String, String> getDeveloperInfo() {
    return {
    'name': 'SahibZ Inventory Management System',
    'version': '1.0.0',
    'author': 'Sarabjeet Singh',
    'email': 'Sarabjeetdevworks@gmail.com',
  };
  }
}
