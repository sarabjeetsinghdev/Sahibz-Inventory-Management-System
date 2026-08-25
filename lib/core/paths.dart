import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppPaths {
  static const String _appFolderName = 'SahibZ';
  static const String _exportsDirName = 'exports';
  static const String _backupsDirName = 'backups';
  static const String _logsDirName = 'logs';
  static const String _databaseName = 'sahibz_inventory.db';

  static Future<String> get appRoot async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, _appFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get databasePath async {
    final root = await appRoot;
    return p.join(root, _databaseName);
  }

  static Future<String> get exportsDir async {
    final root = await appRoot;
    final dir = Directory(p.join(root, _exportsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get backupsDir async {
    final root = await appRoot;
    final dir = Directory(p.join(root, _backupsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get logsDir async {
    final root = await appRoot;
    final dir = Directory(p.join(root, _logsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get errorLogFile async {
    final dir = await logsDir;
    return p.join(dir, 'sahibz_errors.txt');
  }
}
