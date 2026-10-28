import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory ApiException.fromDio(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final serverMessage = _readServerMessage(exception.response?.data);

    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        'The request timed out. Please check your connection and try again.',
      DioExceptionType.connectionError =>
        'Unable to reach the server. Please verify your internet connection.',
      DioExceptionType.badCertificate =>
        'The server certificate could not be verified.',
      DioExceptionType.cancel => 'The request was cancelled.',
      DioExceptionType.badResponse =>
        serverMessage ?? _messageForStatus(statusCode),
      DioExceptionType.unknown =>
        serverMessage ?? 'Something went wrong. Please try again.',
    };

    return ApiException(message, statusCode: statusCode, cause: exception);
  }

  static String? _readServerMessage(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  static String _messageForStatus(int? statusCode) {
    return switch (statusCode) {
      400 => 'The submitted information is invalid.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested record could not be found.',
      409 => 'This record already exists.',
      422 => 'Please review the submitted information and try again.',
      500 ||
      502 ||
      503 ||
      504 => 'The server is temporarily unavailable. Please try again shortly.',
      _ => 'The request could not be completed.',
    };
  }

  @override
  String toString() => message;
}

String readableError(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
