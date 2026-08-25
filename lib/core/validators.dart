class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Enter a valid phone number (at least 10 digits)';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) {
      return '$fieldName must be a positive integer';
    }
    return null;
  }

  static String? validateDecimal(String? value, String fieldName, {int maxDecimals = 2}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final regex = RegExp(r'^\d+(\.\d{1,$maxDecimals})?$');
    if (!regex.hasMatch(value.trim())) {
      return '$fieldName must be a valid number with up to $maxDecimals decimal places';
    }
    return null;
  }

  static String? validateLength(String? value, String fieldName, {int min = 1, int max = 255}) {
    if (value == null || value.trim().isEmpty) {
      if (min > 0) return '$fieldName is required';
      return null;
    }
    final length = value.trim().length;
    if (length < min || length > max) {
      return '$fieldName must be between $min and $max characters';
    }
    return null;
  }

  static String? validateSKU(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[A-Z0-9\-_]{3,50}$');
    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return 'SKU must be 3-50 characters (letters, numbers, hyphen, underscore)';
    }
    return null;
  }

  static String? validateBarcode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8 || digitsOnly.length > 14) {
      return 'Barcode must be 8-14 digits';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain at least one lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain at least one number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Password must contain at least one special character';
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) return 'Confirm password is required';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final formats = ['dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy'];
    for (final _ in formats) {
      try {
        DateTime.parse(value.trim());
        return null;
      } catch (_) {}
    }
    return 'Enter a valid date (dd/MM/yyyy)';
  }

  static String? validateFutureDate(String? value, String fieldName) {
    final error = validateDate(value, fieldName);
    if (error != null) return error;
    final date = DateTime.parse(value!.trim());
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  static String? validatePastDate(String? value, String fieldName) {
    final error = validateDate(value, fieldName);
    if (error != null) return error;
    final date = DateTime.parse(value!.trim());
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }

  static String? validateDateRange(String? start, String? end, String startName, String endName) {
    if (start == null || start.trim().isEmpty) return '$startName is required';
    if (end == null || end.trim().isEmpty) return '$endName is required';
    final startDate = DateTime.parse(start.trim());
    final endDate = DateTime.parse(end.trim());
    if (startDate.isAfter(endDate)) {
      return '$startName cannot be after $endName';
    }
    return null;
  }
}