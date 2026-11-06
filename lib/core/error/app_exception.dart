import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  factory AppException.fromDio(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания сервера';

      case DioExceptionType.connectionError:
        message = 'Нет подключения к интернету';

      case DioExceptionType.badResponse:
        message = 'Ошибка сервера: ${error.response?.statusCode}';

      case DioExceptionType.cancel:
        message = 'Запрос отменён';

      default:
        message = 'Произошла неизвестная ошибка';
    }

    return AppException(
      message: message,
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
