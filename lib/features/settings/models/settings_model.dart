class AppSettings {
  final String companyName;
  final String companyPhone;
  final String companyEmail;
  final String companyAddress;
  final String companyTin;
  final String? companyLogo;
  final String currency;
  final String currencySymbol;
  final double taxRate;
  final String dateFormat;
  final String timeFormat;
  final String language;
  final String theme;
  final String accentColor;
  final int lowStockThreshold;
  final bool autoBackup;
  final String backupFrequency;
  final bool logToFile;

  const AppSettings({
    this.companyName = 'SahibZ Enterprise',
    this.companyPhone = '',
    this.companyEmail = '',
    this.companyAddress = '',
    this.companyTin = '',
    this.companyLogo,
    this.currency = 'PHP',
    this.currencySymbol = '\u20B1',
    this.taxRate = 12.0,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = 'HH:mm',
    this.language = 'en',
    this.theme = 'light',
    this.accentColor = '#2563EB',
    this.lowStockThreshold = 10,
    this.autoBackup = false,
    this.backupFrequency = 'daily',
    this.logToFile = false,
  });

  bool get isDarkTheme => theme == 'dark';
  bool get isLightTheme => theme == 'light';

  AppSettings applySetting(String key, String value) {
    switch (key) {
      case 'company_name':
        return copyWith(companyName: value);
      case 'company_phone':
        return copyWith(companyPhone: value);
      case 'company_email':
        return copyWith(companyEmail: value);
      case 'company_address':
        return copyWith(companyAddress: value);
      case 'company_tin':
        return copyWith(companyTin: value);
      case 'company_logo':
        return value.isEmpty ? copyWith(clearLogo: true) : copyWith(companyLogo: value);
      case 'currency':
        return copyWith(currency: value);
      case 'currency_symbol':
        return copyWith(currencySymbol: value);
      case 'tax_rate':
        return copyWith(taxRate: double.tryParse(value) ?? taxRate);
      case 'date_format':
        return copyWith(dateFormat: value);
      case 'time_format':
        return copyWith(timeFormat: value);
      case 'language':
        return copyWith(language: value);
      case 'theme':
        return copyWith(theme: value);
      case 'accent_color':
        return copyWith(accentColor: value);
      case 'low_stock_threshold':
        return copyWith(lowStockThreshold: int.tryParse(value) ?? lowStockThreshold);
      case 'auto_backup':
        return copyWith(autoBackup: value.toLowerCase() == 'true');
      case 'backup_frequency':
        return copyWith(backupFrequency: value);
      case 'log_to_file':
        return copyWith(logToFile: value.toLowerCase() == 'true');
      default:
        return this;
    }
  }

  AppSettings copyWith({
    String? companyName,
    String? companyPhone,
    String? companyEmail,
    String? companyAddress,
    String? companyTin,
    String? companyLogo,
    String? currency,
    String? currencySymbol,
    double? taxRate,
    String? dateFormat,
    String? timeFormat,
    String? language,
    String? theme,
    String? accentColor,
    int? lowStockThreshold,
    bool? autoBackup,
    String? backupFrequency,
    bool? logToFile,
    bool clearLogo = false,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyAddress: companyAddress ?? this.companyAddress,
      companyTin: companyTin ?? this.companyTin,
      companyLogo: clearLogo ? null : (companyLogo ?? this.companyLogo),
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxRate: taxRate ?? this.taxRate,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      logToFile: logToFile ?? this.logToFile,
    );
  }

  Map<String, String> toMap() {
    return {
      'company_name': companyName,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'company_address': companyAddress,
      'company_tin': companyTin,
      'company_logo': companyLogo ?? '',
      'currency': currency,
      'currency_symbol': currencySymbol,
      'tax_rate': taxRate.toString(),
      'date_format': dateFormat,
      'time_format': timeFormat,
      'language': language,
      'theme': theme,
      'accent_color': accentColor,
      'low_stock_threshold': lowStockThreshold.toString(),
      'auto_backup': autoBackup.toString(),
      'backup_frequency': backupFrequency,
      'log_to_file': logToFile.toString(),
    };
  }

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      companyName: map['company_name'] ?? 'SahibZ Enterprise',
      companyPhone: map['company_phone'] ?? '',
      companyEmail: map['company_email'] ?? '',
      companyAddress: map['company_address'] ?? '',
      companyTin: map['company_tin'] ?? '',
      companyLogo: map['company_logo']?.isNotEmpty == true ? map['company_logo'] : null,
      currency: map['currency'] ?? 'PHP',
      currencySymbol: map['currency_symbol'] ?? '\u20B1',
      taxRate: double.tryParse(map['tax_rate'] ?? '12.0') ?? 12.0,
      dateFormat: map['date_format'] ?? 'dd/MM/yyyy',
      timeFormat: map['time_format'] ?? 'HH:mm',
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'light',
      accentColor: map['accent_color'] ?? '#2563EB',
      lowStockThreshold: int.tryParse(map['low_stock_threshold'] ?? '10') ?? 10,
      autoBackup: map['auto_backup']?.toLowerCase() == 'true',
      backupFrequency: map['backup_frequency'] ?? 'daily',
      logToFile: map['log_to_file']?.toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyPhone': companyPhone,
    'companyEmail': companyEmail,
    'companyAddress': companyAddress,
    'companyTin': companyTin,
    'companyLogo': companyLogo,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'taxRate': taxRate,
    'dateFormat': dateFormat,
    'timeFormat': timeFormat,
    'language': language,
    'theme': theme,
    'accentColor': accentColor,
    'lowStockThreshold': lowStockThreshold,
    'autoBackup': autoBackup,
    'backupFrequency': backupFrequency,
    'logToFile': logToFile,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    companyName: json['companyName'] as String? ?? 'SahibZ Enterprise',
    companyPhone: json['companyPhone'] as String? ?? '',
    companyEmail: json['companyEmail'] as String? ?? '',
    companyAddress: json['companyAddress'] as String? ?? '',
    companyTin: json['companyTin'] as String? ?? '',
    companyLogo: json['companyLogo'] as String?,
    currency: json['currency'] as String? ?? 'PHP',
    currencySymbol: json['currencySymbol'] as String? ?? '\u20B1',
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 12.0,
    dateFormat: json['dateFormat'] as String? ?? 'dd/MM/yyyy',
    timeFormat: json['timeFormat'] as String? ?? 'HH:mm',
    language: json['language'] as String? ?? 'en',
    theme: json['theme'] as String? ?? 'light',
    accentColor: json['accentColor'] as String? ?? '#2563EB',
    lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
    autoBackup: json['autoBackup'] as bool? ?? false,
    backupFrequency: json['backupFrequency'] as String? ?? 'daily',
    logToFile: json['logToFile'] as bool? ?? false,
  );
}
