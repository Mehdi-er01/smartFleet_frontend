import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/auth/presentation/login_page.dart';
import 'package:smartfleet_frontend/main.dart';
import 'package:smartfleet_frontend/core/snackbar_service.dart';
import 'package:smartfleet_frontend/core/storage_service.dart';

class ApiClient {
  late final Dio _dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api',
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
          var publicPaths = ['/auth/register', '/auth/login'];
          bool isPublic = publicPaths.any(
            (path) => options.path.contains(path),
          );
          if (!isPublic) {
            var token = await StorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers["Authorization"] = 'Bearer $token';
            } else {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Authentication token is missing. User logged out.',
                ),
              );
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            StorageService.deleteToken();
            SnackbarService.showError(
              'Your session expired. Please log in again.',
            );
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
            );
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: 'Authentication token is missing. User logged out.',
              ),
            );
          }
          // For all other errors, forward them so the future can complete.
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParametres,
  }) async {
    var response = await _dio.get(endpoint, queryParameters: queryParametres);
    return response;
  }

  Future<Response<dynamic>> post(String endpoint, dynamic data) async {
    var response = await _dio.post(endpoint, data: data);
    return response;
  }

  Future<Response<dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    var response = await _dio.put(endpoint, data: data);
    return response;
  }

  Future<Response<dynamic>> delete(String endpoint) async {
    var response = await _dio.delete(endpoint);
    return response;
  }

  Future<Response<dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    var response = await _dio.patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
    return response;
  }
}

final ApiClientProvider = Provider<ApiClient>((ref) => ApiClient());
