/// Developer information model
/// 
/// Contains information about the developer of the application
/// 
class DeveloperInfo {
  /// Name of the developer
  final String name;
  
  /// Version of the application
  final String version;
  
  /// Author of the application
  final String author;
  
  /// Email of the developer
  final String email;

  DeveloperInfo({
    required this.name,
    required this.version,
    required this.author,
    required this.email,
  });
  
  /// Converts the DeveloperInfo object to a JSON map
  /// 
  /// Returns a map with the following keys:
  /// - name: The name of the developer
  /// - version: The version of the application
  /// - author: The author of the application
  /// - email: The email of the developer
  Map<String, String> toJsonMap() {
    return {'name': name, 'version': version, 'author': author, 'email': email};
  }

  /// Creates a DeveloperInfo object from a JSON map
  /// 
  /// Returns a DeveloperInfo object with the following fields:
  /// - name: The name of the developer
  /// - version: The version of the application
  /// - author: The author of the application
  /// - email: The email of the developer
  factory DeveloperInfo.fromJsonMap(Map<String, String> map) {
    return DeveloperInfo(
      name: map['name'] ?? '',
      version: map['version'] ?? '',
      author: map['author'] ?? '',
      email: map['email'] ?? '',
    );
  }
}