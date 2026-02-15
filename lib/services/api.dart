import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../variables/app.dart';

/// HTTP content type constant for JSON requests
const String contentType = 'application/json';
const Duration timeout = Duration(seconds: 30);

/// Represents a standardized API response wrapper
/// 
/// This class encapsulates result of API calls, providing a consistent
/// structure for handling success, data, and error states across the application.
class ApiResponse {
  /// Indicates whether the API call was successful
  final bool success;
  
  /// Contains the response data when the API call succeeds
  /// Will be null if the call failed or if no data is returned
  final dynamic data;
  
  /// Contains error message when the API call fails
  /// Will be null if the call succeeded
  final String? error;
  
  /// Contains the HTTP status code from the response
  final int statusCode;

  /// Creates a new ApiResponse instance
  /// 
  /// [success] - Whether the API call was successful (required)
  /// [data] - Response data (optional)
  /// [error] - Error message (optional)
  /// [statusCode] - HTTP status code from the response (required)
  ApiResponse({required this.success, this.data, this.error, required this.statusCode});

  bool get successful => success && data != null;
}

class ApiOptions {
  Duration? timeout;

  ApiOptions({this.timeout});
}

/// Service class for handling HTTP API communications
/// 
/// This class provides static methods for making HTTP requests (GET, POST, PUT)
/// to the backend API. It handles request/response formatting, error handling,
/// and environment-specific URL configuration.
class ApiService {
  /// Returns the appropriate base URL based on the build environment
  /// 
  /// Uses development URL when running in debug mode, production URL otherwise.
  /// This allows the app to connect to different API endpoints for testing
  /// and production environments.
  static String get baseUrl => kDebugMode ? APP_URL_API_DEV : APP_URL_API;

  /// Builds common headers for all API requests
  /// 
  /// Includes authentication, app version, and platform information.
  static Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': contentType,
    };

    // Add user ID if available
    final userId = prefs.getString('user_id');
    if (userId != null) {
      headers['X-Client-Id'] = userId;
    }

    // Add app version (hardcoded for now, can be updated later)
    headers['X-App-Version'] = appVersion;

    // Add platform information
    headers['X-Platform'] = Platform.operatingSystem;

    return headers;
  }
  
  /// Makes an HTTP POST request to the specified API endpoint
  /// 
  /// Used for creating new resources on the server (e.g., user registration,
  /// creating preferences, etc.). Automatically handles JSON serialization,
  /// headers, and error responses. Removes 'createdAt' and 'updatedAt' from body.
  /// 
  /// [path] - The API endpoint path (relative to base URL)
  /// [body] - The request body data to be sent as JSON
  /// 
  /// Returns [ApiResponse] with success status, data, or error information
  static Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = Map<String, dynamic>.from(body);
      cleanedBody.remove('createdAt');
      cleanedBody.remove('updatedAt');
      
      log('[api] POST $baseUrl/$path $cleanedBody');

      // Build headers with common information
      final headers = await _buildHeaders();

      // Construct the full URL by combining base URL with endpoint path
      final response = await http.post(
        Uri.parse('$baseUrl/$path'),
        headers: headers,
        // Convert cleaned body map to JSON string for the request
        body: jsonEncode(cleanedBody),
      ).timeout(timeout);

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for successful HTTP status codes (200 OK or 201 Created)
      log('[api] POST $baseUrl/$path response status code: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'],
          statusCode: response.statusCode,
        );
      } else {
        // Handle HTTP error responses with status code information
        return ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to create $path: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Makes an HTTP PUT request to the specified API endpoint
  /// 
  /// Used for updating existing resources on the server (e.g., updating user
  /// profile, modifying preferences, etc.). Automatically handles JSON
  /// serialization, headers, and error responses. Removes 'createdAt' and 'updatedAt' from body.
  /// 
  /// [path] - The API endpoint path (relative to base URL)
  /// [body] - The updated data to be sent as JSON
  /// 
  /// Returns [ApiResponse] with success status, data, or error information
  static Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = Map<String, dynamic>.from(body);
      cleanedBody.remove('createdAt');
      cleanedBody.remove('updatedAt');
      
      log('[api] PUT $baseUrl/$path $cleanedBody');

      // Build headers with common information
      final headers = await _buildHeaders();

      // Construct the full URL and send PUT request with JSON body
      final response = await http.put(
        Uri.parse('$baseUrl/$path'),
        headers: headers,
        body: jsonEncode(cleanedBody),
      ).timeout(timeout);

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK for PUT operations)
      log('[api] PUT /$path response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'],
          statusCode: response.statusCode,
        );
      } else {
        // Handle HTTP error responses with status code information
        return ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to update $path: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Makes an HTTP GET request to the specified API endpoint
  /// 
  /// Used for retrieving data from the server (e.g., fetching user profile,
  /// getting topics list, etc.). Automatically handles headers and error
  /// responses. No request body is sent with GET requests.
  /// 
  /// [path] - The API endpoint path (relative to base URL)
  /// [queryParams] - Optional query parameters to include in the request
  /// 
  /// Returns [ApiResponse] with success status, data, or error information
  static Future<ApiResponse> get(String path, {Map<String, String>? queryParams, ApiOptions? options}) async {
    try {
      log('[api] GET $baseUrl/$path${queryParams != null ? '?${Uri(queryParameters: queryParams).query}' : ''}');

      // Build headers with common information
      final headers = await _buildHeaders();

      // Construct the full URL with query parameters if provided
      var uri = Uri.parse('$baseUrl/$path');
      if (queryParams != null) {
        uri = Uri.parse('$baseUrl/$path').replace(queryParameters: queryParams);
      }

      // Construct the full URL and send GET request (no body needed)
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(options?.timeout ?? timeout);

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK for GET operations)
      log('[api] GET /$path response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          // data: result['data'],
          data: result['data'] ?? result['items'],
          statusCode: response.statusCode,
        );
      } else {
        // Handle HTTP error responses with status code information
        return ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to get $path: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }
}
