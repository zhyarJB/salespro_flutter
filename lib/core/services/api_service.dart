import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../services/auth_service.dart';

/// Centralized API Service
/// Handles all HTTP requests with token management, error handling, and retries
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Get base URL with automatic device detection
  Future<String> getBaseUrl() async {
    return await AuthService.getBaseUrl();
  }

  /// Build full URL from endpoint
  Future<String> buildUrl(String endpoint) async {
    final base = await getBaseUrl();
    // Ensure endpoint starts with /
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  /// Get authentication headers
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await AuthService().getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle HTTP errors
  String _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 
             data['errors']?.toString() ?? 
             'Request failed with status ${response.statusCode}';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }

  /// Handle 401 Unauthorized - token expired
  Future<bool> _handleUnauthorized() async {
    try {
      // Try to refresh token
      final refreshed = await AuthService().refreshToken();
      return refreshed;
    } catch (e) {
      // Refresh failed, user needs to login again
      await AuthService().logout();
      return false;
    }
  }

  /// GET request with retry logic
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool retryOn401 = true,
  }) async {
    final url = await buildUrl(endpoint);
    var uri = Uri.parse(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await http
            .get(uri, headers: headers)
            .timeout(ApiConfig.connectionTimeout);

        // Handle 401 Unauthorized
        if (response.statusCode == 401 && retryOn401 && attempts == 0) {
          final refreshed = await _handleUnauthorized();
          if (refreshed) {
            attempts++;
            continue; // Retry with new token
          } else {
            throw Exception('Authentication failed. Please login again.');
          }
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Request failed after ${ApiConfig.maxRetries} attempts');
  }

  /// POST request with retry logic
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool retryOn401 = true,
  }) async {
    final url = await buildUrl(endpoint);
    final uri = Uri.parse(url);

    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await http
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConfig.connectionTimeout);

        // Handle 401 Unauthorized
        if (response.statusCode == 401 && retryOn401 && attempts == 0) {
          final refreshed = await _handleUnauthorized();
          if (refreshed) {
            attempts++;
            continue; // Retry with new token
          } else {
            throw Exception('Authentication failed. Please login again.');
          }
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Request failed after ${ApiConfig.maxRetries} attempts');
  }

  /// PUT request with retry logic
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool retryOn401 = true,
  }) async {
    final url = await buildUrl(endpoint);
    final uri = Uri.parse(url);

    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await http
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConfig.connectionTimeout);

        // Handle 401 Unauthorized
        if (response.statusCode == 401 && retryOn401 && attempts == 0) {
          final refreshed = await _handleUnauthorized();
          if (refreshed) {
            attempts++;
            continue; // Retry with new token
          } else {
            throw Exception('Authentication failed. Please login again.');
          }
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Request failed after ${ApiConfig.maxRetries} attempts');
  }

  /// DELETE request with retry logic
  Future<http.Response> delete(
    String endpoint, {
    bool retryOn401 = true,
  }) async {
    final url = await buildUrl(endpoint);
    final uri = Uri.parse(url);

    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await http
            .delete(uri, headers: headers)
            .timeout(ApiConfig.connectionTimeout);

        // Handle 401 Unauthorized
        if (response.statusCode == 401 && retryOn401 && attempts == 0) {
          final refreshed = await _handleUnauthorized();
          if (refreshed) {
            attempts++;
            continue; // Retry with new token
          } else {
            throw Exception('Authentication failed. Please login again.');
          }
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Request failed after ${ApiConfig.maxRetries} attempts');
  }

  /// Parse JSON response and handle errors
  Map<String, dynamic> parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response');
      }
    } else {
      throw Exception(_handleError(response));
    }
  }
}

