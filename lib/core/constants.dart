// Core Constants
class AppConstants {
  static const String appName = 'SahibZ Inventory Management System';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'sahibz_inventory.db';
  static const int databaseVersion = 1;

  // API
  static const String baseUrl = 'https://api.sahibz.com/v1';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Security
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  static const String biometricKey = 'biometric_enabled';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String serverDateFormat = 'yyyy-MM-dd';
  static const String serverDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  // Currency
  static const String defaultCurrency = 'PHP';
  static const String currencySymbol = '\u20B1';

  // Tax
  static const double defaultTaxRate = 12.0;

  // Barcode
  static const String barcodeFormat = 'CODE128';

  // File Extensions
  static const String pdfExtension = '.pdf';
  static const String excelExtension = '.xlsx';
  static const String csvExtension = '.csv';
  static const String backupExtension = '.backup';

  // Export
  static const int exportBatchSize = 1000;

  // Backup
  static const int maxBackupFiles = 10;
  static const String backupDirectoryName = 'backups';
}