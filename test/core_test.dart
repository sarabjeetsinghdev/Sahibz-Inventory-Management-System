import 'package:flutter_test/flutter_test.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/validators.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/core/constants.dart';

void main() {
  group('Result Tests', () {
    test('Success result should have correct value', () {
      const result = Success<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, equals(42));
    });

    test('Failure result should have correct error', () {
      final error = NetworkException('Network error');
      final result = Failure<int>(error);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error.message, equals('Network error'));
    });

    test('getOrThrow should return value for success', () {
      const result = Success<String>('test');
      expect(result.getOrThrow(), equals('test'));
    });

    test('getOrThrow should throw for failure', () {
      final result = Failure<String>(NetworkException('error'));
      expect(() => result.getOrThrow(), throwsException);
    });
  });

  group('Validator Tests', () {
    test('validateRequired should return error for null', () {
      expect(Validators.validateRequired(null, 'Name'), isNotNull);
      expect(Validators.validateRequired('', 'Name'), isNotNull);
      expect(Validators.validateRequired('  ', 'Name'), isNotNull);
    });

    test('validateRequired should pass for non-empty', () {
      expect(Validators.validateRequired('John', 'Name'), isNull);
    });

    test('validateEmail should validate correctly', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(null), isNull);
    });

    test('validatePhone should validate correctly', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(null), isNull);
    });

    test('validatePassword should check strength', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('short'), isNotNull);
      expect(Validators.validatePassword('abcdefgh'), isNotNull);
      expect(Validators.validatePassword('Abc123!@'), isNull);
      expect(Validators.validatePassword('StrongPass1!'), isNull);
    });

    test('validateSKU should validate correctly', () {
      expect(Validators.validateSKU('PROD-001'), isNull);
      expect(Validators.validateSKU('AB'), isNotNull);
      expect(Validators.validateSKU(null), isNull);
    });
  });

  group('Extension Tests', () {
    test('String capitalize should work', () {
      expect('hello'.capitalize, equals('Hello'));
      expect(''.capitalize, equals(''));
    });

    test('String titleCase should work', () {
      expect('hello world'.titleCase, equals('Hello World'));
    });

    test('String snakeCase should work', () {
      expect('helloWorld'.snakeCase, equals('hello_world'));
    });

    test('CurrencyFormatter should format correctly', () {
      expect(CurrencyFormatter.format(1000), contains('1,000'));
      expect(CurrencyFormatter.format(1000000),
          equals('\u20B11,000,000.00'));
    });

    test('NumberFormatter should format integers', () {
      expect(NumberFormatter.formatInteger(1000), equals('1,000'));
      expect(NumberFormatter.formatInteger(1000000), equals('1,000,000'));
    });
  });

  group('AppConstants Tests', () {
    test('App name should be set correctly', () {
      expect(AppConstants.appName, equals('SahibZ Inventory Management System'));
    });

    test('Default page size should be 20', () {
      expect(AppConstants.defaultPageSize, equals(20));
    });

    test('Default currency should be PHP', () {
      expect(AppConstants.defaultCurrency, equals('PHP'));
    });
  });
}
