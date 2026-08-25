import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sahibz_inventory/core/paths.dart';

class AppLogger {
  static const String _tag = 'SahibZ';
  static bool _isDebug = kDebugMode;
  static bool _fileLoggingEnabled = false;
  static String? _filePath;

  static void setDebugMode(bool debug) => _isDebug = debug;

  static Future<void> setFileLogging({required bool enabled}) async {
    _fileLoggingEnabled = enabled;
    if (enabled) {
      try {
        _filePath = await AppPaths.errorLogFile;
      } catch (e) {
        _fileLoggingEnabled = false;
        _filePath = null;
        debugPrint('[$_tag] Failed to resolve log file path: $e');
      }
    } else {
      _filePath = null;
    }
  }

  static Future<void> _appendToFile(String line) async {
    final path = _filePath;
    if (path == null) return;
    try {
      final file = File(path);
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[$_tag] Failed to write log file: $e');
    }
  }

  static void _log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isDebug && level != LogLevel.error && level != LogLevel.warning) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[$timestamp] [$_tag] [${level.name.toUpperCase()}]';
    final output = '$prefix $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack: $stackTrace' : ''}';

    if (_fileLoggingEnabled) {
      unawaited(_appendToFile(output));
    }

    switch (level) {
      case LogLevel.wtf:
      case LogLevel.verbose:
      case LogLevel.debug:
        debugPrint(output);
        break;
      case LogLevel.info:
        debugPrint(output);
        break;
      case LogLevel.warning:
        debugPrint(output);
        break;
      case LogLevel.error:
        debugPrint(output);
        break;
    }
  }

  static void v(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.verbose, message, error, stackTrace);

  static void d(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.debug, message, error, stackTrace);

  static void i(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.info, message, error, stackTrace);

  static void w(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, message, error, stackTrace);

  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) =>
      _log(LogLevel.wtf, message, error, stackTrace);
}

enum LogLevel { verbose, debug, info, warning, error, wtf }

class AppLoggerExtension {
  static void logNetwork(String method, String url, {int? statusCode, dynamic data}) {
    AppLogger.d('[$method] $url${statusCode != null ? ' [$statusCode]' : ''}${data != null ? '\nResponse: $data' : ''}');
  }

  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    AppLogger.e('[$context] $error', error, stackTrace);
  }

  static void logPerformance(String operation, Duration duration) {
    AppLogger.d('[PERF] $operation took ${duration.inMilliseconds}ms');
  }
}