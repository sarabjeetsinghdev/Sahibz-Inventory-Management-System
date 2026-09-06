// Result Types
import 'package:sahibz_inventory/core/exceptions.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get value => (this as Success<T>).value;
  AppException get error => (this as Failure<T>).error;

  T? get valueOrNull => isSuccess ? value : null;
  AppException? get errorOrNull => isFailure ? error : null;

  R fold<R>(R Function(T) onSuccess, R Function(AppException) onFailure) {
    if (isSuccess) return onSuccess(value);
    return onFailure(error);
  }

  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) return Success(transform(value));
    return Failure(error);
  }

  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isSuccess) return transform(value);
    return Failure(error);
  }
}

class Success<T> extends Result<T> {
  @override
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  @override
  final AppException error;
  const Failure(this.error);
}

extension ResultExtension<T> on Result<T> {
  T getOrThrow() {
    if (isSuccess) return value;
    throw error;
  }

  T getOrDefault(T defaultValue) => isSuccess ? value : defaultValue;

  Future<Result<R>> asyncMap<R>(Future<R> Function(T) transform) async {
    if (isFailure) return Failure(error);
    try {
      final result = await transform(value);
      return Success(result);
    } catch (e) {
      return Failure(AppException(e.toString()));
    }
  }
}