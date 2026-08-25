class UpdateManifest {
  final String latestVersion;
  final int buildNumber;
  final String? minVersion;
  final String? releaseDate;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? fileName;
  final String? checksum;

  const UpdateManifest({
    required this.latestVersion,
    required this.buildNumber,
    this.minVersion,
    this.releaseDate,
    this.releaseNotes,
    this.downloadUrl,
    this.fileName,
    this.checksum,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      latestVersion: json['latestVersion'] as String,
      buildNumber: json['buildNumber'] as int,
      minVersion: json['minVersion'] as String?,
      releaseDate: json['releaseDate'] as String?,
      releaseNotes: json['releaseNotes'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      fileName: json['fileName'] as String?,
      checksum: json['checksum'] as String?,
    );
  }
}
