import 'package:dio/dio.dart';
import 'package:herlife/core/config/app_config.dart';
import 'package:herlife/services/token_storage_service.dart';

typedef UnauthorizedCallback = void Function();

/// Centralized API HTTP client wrapping [Dio].
/// Handles base options, authentication interceptors, and error formatting.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  /// Optional callback invoked on 401 Unauthorized errors to notify auth state listeners.
  /// Decoupled from UI: Does NOT perform direct Navigator calls.
  UnauthorizedCallback? onUnauthorized;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically set baseUrl in case it was updated
          options.baseUrl = AppConfig.baseUrl;

          final token = await TokenStorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await TokenStorageService.clearToken();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Underlying Dio instance.
  Dio get dio => _dio;

  /// Helper to extract clean error message from Dio exceptions.
  static String formatError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Unable to reach HerLife server. Please check your internet connection.';
      }

      if (error.response != null && error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) return detail;
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              return first['msg'].toString();
            }
          }
        }
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
