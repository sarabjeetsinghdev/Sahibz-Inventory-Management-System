class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(super.message, {this.statusCode, super.code, super.originalError, super.stackTrace});
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.originalError, super.stackTrace});
}

class AuthorizationException extends AppException {
  const AuthorizationException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException(super.message, {this.errors, super.code, super.originalError, super.stackTrace});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError, super.stackTrace});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError, super.stackTrace});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ConflictException extends AppException {
  const ConflictException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode, super.code, super.originalError, super.stackTrace});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.originalError, super.stackTrace});
}

class CacheMissException extends AppException {
  const CacheMissException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ParsingException extends AppException {
  const ParsingException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ExportException extends AppException {
  const ExportException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ImportException extends AppException {
  const ImportException(super.message, {super.code, super.originalError, super.stackTrace});
}

class BackupException extends AppException {
  const BackupException(super.message, {super.code, super.originalError, super.stackTrace});
}

class RestoreException extends AppException {
  const RestoreException(super.message, {super.code, super.originalError, super.stackTrace});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError, super.stackTrace});
}

class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message, {super.code, super.originalError, super.stackTrace});
}

class BiometricException extends AppException {
  const BiometricException(super.message, {super.code, super.originalError, super.stackTrace});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError, super.stackTrace});
}

class FileException extends AppException {
  const FileException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ExportFormatException extends AppException {
  const ExportFormatException(super.message, {super.code, super.originalError, super.stackTrace});
}

class PrintException extends AppException {
  const PrintException(super.message, {super.code, super.originalError, super.stackTrace});
}