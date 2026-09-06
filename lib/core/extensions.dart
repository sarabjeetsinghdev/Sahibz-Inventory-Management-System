import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/result.dart';

extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');

  String get camelCase {
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return '';
    return words.first.toLowerCase() + words.skip(1).map((w) => w.capitalize).join();
  }

  String get snakeCase => replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}').replaceAll(RegExp(r'[-\s]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidPhone => replaceAll(RegExp(r'\D'), '').length >= 10;

  String get digitsOnly => replaceAll(RegExp(r'\D'), '');

  String get alphanumericOnly => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  String truncate(int length, {String suffix = '...'}) => length >= this.length ? this : '${substring(0, length)}$suffix';

  String? get nullIfEmpty => trim().isEmpty ? null : this;

  String get removeExtraSpaces => replaceAll(RegExp(r'\s+'), ' ').trim();

  List<String> get lines => split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String mask({int visibleStart = 2, int visibleEnd = 2, String maskChar = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final masked = maskChar * (length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  String get formattedDateTime => '$formattedDate $formattedTime';

  String get formattedTime => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get formattedTimeWithSeconds => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';

  String get isoDate => toIso8601String().split('T').first;

  String get isoDateTime => toIso8601String();

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).startOfDay;

  DateTime get endOfWeek => add(Duration(days: 7 - weekday)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month).startOfDay;

  DateTime get endOfMonth => DateTime(year, month + 1).subtract(const Duration(days: 1)).endOfDay;

  DateTime get startOfYear => DateTime(year).startOfDay;

  DateTime get endOfYear => DateTime(year + 1).subtract(const Duration(days: 1)).endOfDay;

  bool get isToday => DateTime.now().difference(this).inDays == 0;

  bool get isYesterday => DateTime.now().difference(this).inDays == 1;

  bool get isThisWeek => DateTime.now().startOfWeek.isBefore(this) && DateTime.now().endOfWeek.isAfter(this);

  bool get isThisMonth => DateTime.now().startOfMonth.isBefore(this) && DateTime.now().endOfMonth.isAfter(this);

  bool get isThisYear => DateTime.now().startOfYear.isBefore(this) && DateTime.now().endOfYear.isAfter(this);

  int get daysUntil => DateTime.now().difference(this).inDays.abs();

  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

extension NumberExtensions on num {
  String get formattedCurrency => CurrencyFormatter.format(this);

  String get formattedInteger => toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},');

  String get formattedCompact => toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},');

  double get rounded2 => (this * 100).round() / 100;

  int get toIntSafe => isNaN ? 0 : (this as double).toInt();

  double get toDoubleSafe => isNaN ? 0.0 : (this as double);

  String get withCommas => toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},');
}

extension ListExtensions<T> on List<T> {
  List<T> distinctBy<K>(K Function(T) key) {
    final seen = <K>{};
    return where((element) => seen.add(key(element))).toList();
  }

  List<List<T>> chunk(int size) {
    if (size <= 0) return [this];
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, min(i + size, length)));
    }
    return chunks;
  }

  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;

  List<T> get shuffledCopy => [...this]..shuffle();
}

extension MapExtensions<K, V> on Map<K, V> {
  V? getOrElse(K key, V Function() defaultValue) => containsKey(key) ? this[key]! : defaultValue();

  Map<K, V2> mapValues<V2>(V2 Function(V) transform) => map((key, value) => MapEntry(key, transform(value)));
}

extension AsyncValueExtensions<T> on AsyncValue<T> {
  bool get isLoading => this is AsyncLoading;
  bool get isError => this is AsyncError;
  bool get hasValue => this is AsyncData;

  T? get valueOrNull => this is AsyncData<T> ? (this as AsyncData<T>).value : null;

  Object? get errorOrNull => this is AsyncError ? (this as AsyncError).error : null;
}

extension FutureExtensions<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Success(value);
    } catch (e, stackTrace) {
      return Failure(AppException(e.toString(), originalError: e, stackTrace: stackTrace));
    }
  }
}

class CurrencyFormatter {
  static String _symbol = '\u20B1';
  static const int _decimals = 2;

  static String get symbol => _symbol;

  static void setSymbol(String symbol) {
    if (symbol.trim().isNotEmpty) _symbol = symbol.trim();
  }

  static String format(num value, {String? symbol, int decimals = _decimals}) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';
    final formatted = absValue.toStringAsFixed(decimals).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return '$sign${symbol ?? _symbol}$formatted';
  }

  static String formatCompact(num value, {String? symbol}) {
    if (value >= 10000000) {
      return '${format(value / 10000000, symbol: '', decimals: 2)} Cr';
    } else if (value >= 100000) {
      return '${format(value / 100000, symbol: '', decimals: 2)} L';
    } else if (value >= 1000) {
      return '${format(value / 1000, symbol: '', decimals: 2)} K';
    }
    return format(value, symbol: symbol ?? _symbol);
  }

  static double parse(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
  }
}

class NumberFormatter {
  static String formatInteger(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  static String formatPercent(double value, {int decimals = 2}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }
}