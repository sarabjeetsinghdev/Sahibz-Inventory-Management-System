import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/features/updates/models/update_manifest.dart';
import 'package:sahibz_inventory/features/updates/services/update_service.dart';

enum UpdateStatus { idle, checking, available, downloading, ready, error }

class UpdateState {
  final UpdateStatus status;
  final UpdateManifest? manifest;
  final double progress;
  final String? error;
  final String currentVersion;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.manifest,
    this.progress = 0.0,
    this.error,
    this.currentVersion = 'unknown',
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateManifest? manifest,
    double? progress,
    String? error,
    String? currentVersion,
  }) {
    return UpdateState(
      status: status ?? this.status,
      manifest: manifest ?? this.manifest,
      progress: progress ?? this.progress,
      error: error,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  UpdateService get _service => ref.read(updateServiceProvider);

  Future<void> init() async {
    final version = await _service.getCurrentVersion();
    state = state.copyWith(currentVersion: version);
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(status: UpdateStatus.checking, error: null);

    final result = await _service.checkForUpdate();

    if (result.manifest != null) {
      state = state.copyWith(
        status: UpdateStatus.available,
        manifest: result.manifest,
      );
    } else if (result.error != null) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: result.error,
      );
    } else {
      state = state.copyWith(status: UpdateStatus.idle);
    }
  }

  Future<void> downloadUpdate() async {
    final manifest = state.manifest;
    if (manifest == null || manifest.downloadUrl == null) return;

    state = state.copyWith(status: UpdateStatus.downloading, progress: 0.0);

    try {
      String fileName = manifest.fileName?.trim() ?? '';
      if (fileName.isEmpty) {
        final uri = Uri.parse(manifest.downloadUrl!);
        fileName = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'sahibz-update-${manifest.latestVersion}.exe';
      }

      final filePath = await _service.downloadUpdate(
        url: manifest.downloadUrl!,
        fileName: fileName,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        status: UpdateStatus.ready,
        progress: 1.0,
      );

      final result = await _service.launchInstaller(filePath);
      if (result.exitCode == 0) {
        _exitApp();
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: e.toString(),
      );
    }
  }

  void _exitApp() {
    unawaited(Future.delayed(const Duration(milliseconds: 500), () {
      exit(0);
    }));
  }

  void reset() {
    state = const UpdateState();
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    manifestUrl: 'https://www.google.com',
  );
});

final updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
