/// Cache / Local storage exception
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache exception occurred']);

  @override
  String toString() => 'CacheException: $message';
}

/// Validation exception
class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Validation exception occurred']);

  @override
  String toString() => 'ValidationException: $message';
}
