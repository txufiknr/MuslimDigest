import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/utils/offline_queue.dart';

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

  /// Contains the full JSON response as a map
  final Map<String, dynamic>? result;

  /// Creates a new ApiResponse instance
  /// 
  /// [success] - Whether the API call was successful (required)
  /// [data] - Response data (optional)
  /// [error] - Error message (optional)
  /// [statusCode] - HTTP status code from the response (required)
  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
    this.result,
  });

  bool get successful => success && data != null;
}

class ApiOptions {
  Duration? timeout;

  ApiOptions({this.timeout});
}

/// Enhanced API service with offline support
/// 
/// This service provides all functionality of the original ApiService
/// plus automatic offline queuing for failed requests. When a request
/// fails due to network issues, it's automatically queued for retry
/// when connectivity is restored.
class ApiService {
  /// Returns the appropriate base URL based on the build environment
  /// 
  /// Uses development URL when running in debug mode, production URL otherwise.
  /// This allows the app to connect to different API endpoints for testing
  /// and production environments.
  static String get baseUrl => APP_IS_PRODUCTION || APP_USE_PRODUCTION_API ? APP_URL_API : APP_URL_API_DEV;

  /// Builds common headers for all API requests
  /// 
  /// Includes authentication, app version, and platform information.
  static Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': contentType,
    };

    // Add user ID
    headers['X-Client-Id'] = PrefData.user.userId;

    // Add app version (hardcoded for now, can be updated later)
    headers['X-App-Version'] = appVersion;

    // Add platform information
    headers['X-Platform'] = Platform.operatingSystem;

    return headers;
  }

  /// Execute a POST request with offline support
  /// 
  /// If the request fails due to network issues, it will be queued
  /// for automatic retry when connectivity is restored.
  /// 
  /// [path] - API endpoint path
  /// [body] - Request body data
  /// [queueOffline] - Whether to queue failed requests (default: true)
  /// 
  /// Returns [ApiResponse] with success status, data, or error information
  static Future<ApiResponse> post(
    String path, 
    Map<String, dynamic> body, {
    bool queueOffline = true,
  }) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = Map<String, dynamic>.from(body);
      cleanedBody.remove('createdAt');
      cleanedBody.remove('updatedAt');
      
      log('🌐 POST /$path $cleanedBody');

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
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      log('🌐 POST /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'],
          statusCode: response.statusCode,
          result: result,
        );
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to create $path: ${response.statusCode}',
          statusCode: response.statusCode,
          result: result,
        );
        
        // If request failed due to network issues and offline queuing is enabled
        if (queueOffline && _isNetworkError(apiResponse)) {
          log('[ApiService] Network error detected, queuing POST /$path');
          await OfflineQueueService.queueRequest(
            method: 'POST',
            endpoint: path,
            data: cleanedBody,
          );
        }
        
        return apiResponse;
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      log('🌐 POST /$path response status code: $e ❌');
      
      final apiResponse = ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
      
      // If exception occurs and offline queuing is enabled
      if (queueOffline) {
        log('[ApiService] Exception occurred, queuing POST /$path: $e');
        await OfflineQueueService.queueRequest(
          method: 'POST',
          endpoint: path,
          data: body,
        );
      }
      
      return apiResponse;
    }
  }

  /// Execute a PUT request with offline support
  static Future<ApiResponse> put(
    String path, 
    Map<String, dynamic> body, {
    bool queueOffline = true,
  }) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = Map<String, dynamic>.from(body);
      cleanedBody.remove('createdAt');
      cleanedBody.remove('updatedAt');
      
      log('🌐 PUT /$path $cleanedBody');

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
      final isSuccess = response.statusCode == 200;
      log('🌐 PUT /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'],
          statusCode: response.statusCode,
          result: result,
        );
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to update $path: ${response.statusCode}',
          statusCode: response.statusCode,
          result: result,
        );
        
        if (queueOffline && _isNetworkError(apiResponse)) {
          log('[ApiService] Network error detected, queuing PUT /$path');
          await OfflineQueueService.queueRequest(
            method: 'PUT',
            endpoint: path,
            data: cleanedBody,
          );
        }
        
        return apiResponse;
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      log('🌐 PUT /$path response status code: $e ❌');
      
      final apiResponse = ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
      
      if (queueOffline) {
        log('[ApiService] Exception occurred, queuing PUT /$path: $e');
        await OfflineQueueService.queueRequest(
          method: 'PUT',
          endpoint: path,
          data: body,
        );
      }
      
      return apiResponse;
    }
  }

  /// Execute a DELETE request with offline support
  static Future<ApiResponse> delete(
    String path, {
    bool queueOffline = true,
  }) async {
    try {
      log('🌐 DELETE /$path');

      // Build headers with common information
      final headers = await _buildHeaders();

      // Construct the full URL and send DELETE request (no body needed)
      final response = await http.delete(
        Uri.parse('$baseUrl/$path'),
        headers: headers,
      ).timeout(timeout);

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK or 204 No Content for DELETE operations)
      final isSuccess = response.statusCode == 200 || response.statusCode == 204;
      log('🌐 DELETE /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'],
          statusCode: response.statusCode,
          result: result,
        );
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to delete $path: ${response.statusCode}',
          statusCode: response.statusCode,
          result: result,
        );
        
        if (queueOffline && _isNetworkError(apiResponse)) {
          log('[ApiService] Network error detected, queuing DELETE /$path');
          await OfflineQueueService.queueRequest(
            method: 'DELETE',
            endpoint: path,
            data: {}, // DELETE requests typically don't have body
          );
        }
        
        return apiResponse;
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      log('🌐 DELETE /$path response status code: $e ❌');
      
      final apiResponse = ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
      
      if (queueOffline) {
        log('[ApiService] Exception occurred, queuing DELETE /$path: $e');
        await OfflineQueueService.queueRequest(
          method: 'DELETE',
          endpoint: path,
          data: {},
        );
      }
      
      return apiResponse;
    }
  }

  /// Execute a GET request with offline support
  /// 
  /// Note: GET requests are typically not queued as they are read-only
  /// but we still provide the interface for consistency
  static Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParams,
    ApiOptions? options,
    bool queueOffline = false, // Default to false for GET requests
  }) async {
    try {
      log('🌐 GET /$path${queryParams != null ? '?${Uri(queryParameters: queryParams).query}' : ''}');

      // Build headers with common information
      final headers = await _buildHeaders();
      log('🌐 GET headers: $headers');

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
      final isSuccess = response.statusCode == 200;
      log('🌐 GET /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse(
          success: result['success'] ?? true,
          data: result['data'] ?? result['items'],
          statusCode: response.statusCode,
          result: result,
        );
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse(
          success: false,
          error: result['error'] ?? 'Failed to get $path: ${response.statusCode}',
          statusCode: response.statusCode,
          result: result,
        );
        
        // Generally don't queue GET requests, but option is available
        if (queueOffline && _isNetworkError(apiResponse)) {
          log('[ApiService] Network error detected, queuing GET /$path');
          await OfflineQueueService.queueRequest(
            method: 'GET',
            endpoint: path,
            data: queryParams ?? {},
          );
        }
        
        return apiResponse;
      }
    } catch (e) {
      // Handle network-level errors (connection timeout, DNS failure, etc.)
      log('🌐 GET /$path response status code: $e ❌');
      
      final apiResponse = ApiResponse(
        success: false,
        error: 'Network error: $e',
        statusCode: 0,
      );
      
      if (queueOffline) {
        log('[ApiService] Exception occurred, queuing GET /$path: $e');
        await OfflineQueueService.queueRequest(
          method: 'GET',
          endpoint: path,
          data: queryParams ?? {},
        );
      }
      
      return apiResponse;
    }
  }

  /// Process offline queue and retry failed requests
  /// 
  /// This method should be called when:
  /// - App starts (in splash screen)
  /// - Connectivity is restored
  /// - User manually triggers sync
  /// 
  /// Returns number of successfully processed requests
  static Future<int> processOfflineQueue() async {
    log('[ApiService] Processing offline queue...');
    
    return await OfflineQueueService.processQueue(
      executeRequest: _executeQueuedRequest,
    );
  }

  /// Execute a queued request using the same logic as direct requests
  static Future<ApiResponse> _executeQueuedRequest(
    String method,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    switch (method.toUpperCase()) {
      case 'POST':
        return await post(endpoint, data, queueOffline: false); // Don't queue queued requests
      case 'PUT':
        return await put(endpoint, data, queueOffline: false);
      case 'DELETE':
        return await delete(endpoint, queueOffline: false);
      case 'GET':
        return await get(endpoint, 
            queryParams: data.map((k, v) => MapEntry(k, v.toString())),
            queueOffline: false);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  /// Check if an API response indicates a network error
  static bool _isNetworkError(ApiResponse response) {
    // Status code 0 typically indicates network connectivity issues
    return response.statusCode == 0 || 
           response.error?.toLowerCase().contains('network') == true ||
           response.error?.toLowerCase().contains('connection') == true ||
           response.error?.toLowerCase().contains('timeout') == true;
  }

  /// Get offline queue statistics
  static Future<Map<String, dynamic>> getQueueStats() async {
    return await OfflineQueueService.getQueueStats();
  }

  /// Clear all queued requests
  static Future<void> clearQueue() async {
    await OfflineQueueService.clearQueue();
  }
}
