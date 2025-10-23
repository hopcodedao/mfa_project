import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile_app/src/constants/app_constants.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: AppConstants.requestTimeout);
  static const int _maxRetries = 3;

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    int retryCount = 0,
  }) async {
    try {
      final response = await request().timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      throw Exception('Kết nối quá chậm, vui lòng thử lại');
    } on SocketException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      throw Exception('Không có kết nối internet');
    } catch (e) {
      if (retryCount < _maxRetries && !e.toString().contains('401')) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    return _makeRequest(() => http.get(url, headers: headers));
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    return _makeRequest(
      () => http.post(url, headers: headers, body: json.encode(data)),
    );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    return _makeRequest(
      () => http.put(url, headers: headers, body: json.encode(data)),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    return _makeRequest(() => http.delete(url, headers: headers));
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Phiên đăng nhập đã hết hạn');
    } else if (response.statusCode == 403) {
      throw ForbiddenException('Không có quyền truy cập');
    } else if (response.statusCode == 404) {
      throw NotFoundException('Không tìm thấy dữ liệu');
    } else if (response.statusCode >= 500) {
      throw ServerException('Lỗi máy chủ, vui lòng thử lại sau');
    } else {
      throw ApiException('Lỗi không xác định: ${response.statusCode}');
    }
  }
}

// Custom Exception Classes
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}
