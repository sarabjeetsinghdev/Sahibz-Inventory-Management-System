import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sahibz_inventory/features/updates/models/update_manifest.dart';

class UpdateCheckResult {
  final bool success;
  final UpdateManifest? manifest;
  final String? error;

  const UpdateCheckResult({this.success = false, this.manifest, this.error});
}

class UpdateService {
  final String manifestUrl;
  final Dio _dio;

  UpdateService({required this.manifestUrl, Dio? dio})
      : _dio = dio ?? Dio();

  Future<PackageInfo> _getPackageInfo() => PackageInfo.fromPlatform();

  List<int> _parseVersion(String v) {
    final main = v.split('-').first.split('+').first;
    final parts = main.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '') ?? 0,
    ];
  }

  int _compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return 0;
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final response = await _dio.get(manifestUrl);
      
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          error: 'Server returned status ${response.statusCode}.',
        );
      }

      if (response.data is String) {
        response.data = jsonDecode(response.data);
      }

      final manifest = UpdateManifest.fromJson(
          response.data as Map<String, dynamic>);
      final info = await _getPackageInfo();

      final versionCmp = _compareVersions(manifest.latestVersion, info.version);
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final isNewer = versionCmp > 0 ||
          (versionCmp == 0 && manifest.buildNumber > currentBuild);

      if (isNewer) {
        return UpdateCheckResult(success: true, manifest: manifest);
      }
      return const UpdateCheckResult(success: true);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return const UpdateCheckResult(
              error: 'Connection timed out. Please check your internet.');
        case DioExceptionType.receiveTimeout:
          return const UpdateCheckResult(
              error: 'Server took too long to respond. Try again later.');
        case DioExceptionType.connectionError:
          return const UpdateCheckResult(
              error: 'Could not connect to update server. '
                  'Check your internet connection.');
        case DioExceptionType.badResponse:
          return UpdateCheckResult(
              error: 'Server error (${e.response?.statusCode}).');
        default:
          return UpdateCheckResult(
              error: 'Network error: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      return UpdateCheckResult(error: 'Update check failed: $e');
    }
  }

  Future<String> downloadUpdate({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}\\$fileName';

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    return filePath;
  }

  Future<ProcessResult> launchInstaller(String installerPath) async {
    return Process.run(installerPath, ['/SILENT', '/VERYSILENT'],
        runInShell: true);
  }

  Future<String> extractZip(String zipPath, String destinationDir) async {
    final dir = Directory(destinationDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);

    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    await extractArchiveToDisk(archive, destinationDir);

    // If the zip wrapped everything in a single folder, use that as root.
    final entries = dir.listSync();
    final dirs = entries.whereType<Directory>().toList();
    if (entries.length == 1 && dirs.length == 1) {
      return dirs.first.path;
    }
    return destinationDir;
  }

  Future<bool> applyZipUpdate({
    required String zipPath,
    required String version,
  }) async {
    final exePath = Platform.resolvedExecutable;
    final installDir = p.dirname(exePath);
    final exeName = p.basename(exePath);

    final tempDir = await getTemporaryDirectory();
    final extractDir =
        p.join(tempDir.path, 'sahibz_update_$version');
    final sourceDir = await extractZip(zipPath, extractDir);

    final batName = 'apply_update_$version.bat';
    final batPath = p.join(tempDir.path, batName);
    final script = '''
@echo off
timeout /t 3 /nobreak >nul
taskkill /f /im "$exeName" >nul 2>&1
xcopy /e /y /i "${sourceDir.replaceAll('/', '\\')}\\*" "${installDir.replaceAll('/', '\\')}\\"
cd /d "${installDir.replaceAll('/', '\\')}"
start "" "${installDir.replaceAll('/', '\\')}\\$exeName"
del "%~f0"
''';
    await File(batPath).writeAsString(script);

    await Process.start(
      'cmd.exe',
      ['/c', batPath],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
    return true;
  }

  Future<String> getCurrentVersion() async {
    final info = await _getPackageInfo();
    return '${info.version}+${info.buildNumber}';
  }
}
