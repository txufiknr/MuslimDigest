import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
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

  /// Factory constructor for cancelled requests
  factory ApiResponse.cancelled() {
    return ApiResponse(
      success: false,
      error: 'Request cancelled',
      statusCode: 0,
    );
  }

  /// Factory constructor for successful responses
  factory ApiResponse.success(Map<String, dynamic> result, int statusCode) {
    return ApiResponse(
      success: result['success'] ?? true,
      data: result['data'] ?? result['items'], // Handle both data and items fields
      statusCode: statusCode,
      result: result,
    );
  }

  /// Factory constructor for error responses
  factory ApiResponse.error(String action, String path, int statusCode, Map<String, dynamic> result) {
    return ApiResponse(
      success: false,
      error: result['error'] ?? 'Failed to $action $path: $statusCode',
      statusCode: statusCode,
      result: result,
    );
  }

  /// Factory constructor for network errors
  factory ApiResponse.networkError(String message, {int statusCode = 0}) {
    return ApiResponse(
      success: false,
      error: 'Network error: $message',
      statusCode: statusCode,
    );
  }

  bool get successful => success && data != null;
}

class ApiOptions {
  Duration? timeout;
  CancelToken? cancelToken;

  ApiOptions({this.timeout, this.cancelToken});
}

/// Enhanced API service with offline support using Dio
/// 
/// This service provides all functionality of the original ApiService
/// plus automatic offline queuing for failed requests. When a request
/// fails due to network issues, it's automatically queued for retry
/// when connectivity is restored.
class ApiService {
  static Dio? _dio;
  static final Map<String, CancelToken> _activeRequests = {};

  /// Returns the appropriate base URL based on the build environment
  /// 
  /// Uses development URL when running in debug mode, production URL otherwise.
  /// This allows the app to connect to different API endpoints for testing
  /// and production environments.
  static String get baseUrl => APP_IS_PRODUCTION || APP_USE_PRODUCTION_API ? APP_URL_API : APP_URL_API_DEV;

  /// Get or create Dio instance with common configuration
  static Dio get dio {
    _dio ??= Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'Content-Type': contentType,
      },
    ));
    return _dio!;
  }

  /// Create a new cancel token for request tracking
  static CancelToken _createCancelToken(String requestId) {
    // Cancel existing request with same ID if any
    _cancelRequest(requestId);
    
    final cancelToken = CancelToken();
    _activeRequests[requestId] = cancelToken;
    
    // Clean up when request completes or is cancelled
    cancelToken.whenCancel.then((_) {
      _activeRequests.remove(requestId);
      log('[ApiService] Request $requestId cancelled');
    });
    
    return cancelToken;
  }

  /// Cancel a specific request by ID
  static void _cancelRequest(String requestId) {
    final existingToken = _activeRequests[requestId];
    if (existingToken != null && !existingToken.isCancelled) {
      existingToken.cancel('Request cancelled by newer request');
      log('[ApiService] Cancelled previous request: $requestId');
    }
  }

  /// Cancel all active requests
  static void cancelAllRequests() {
    for (final requestId in _activeRequests.keys) {
      _cancelRequest(requestId);
    }
    log('[ApiService] Cancelled all active requests');
  }

  /// Get count of active requests
  static int get activeRequestCount => _activeRequests.length;

  /// Clean body data by removing timestamp fields
  static Map<String, dynamic> _cleanBody(Map<String, dynamic> body) {
    final cleanedBody = Map<String, dynamic>.from(body);
    cleanedBody.remove('createdAt');
    cleanedBody.remove('updatedAt');
    return cleanedBody;
  }

  /// Handle DioException with cancellation check and offline queuing
  static Future<ApiResponse> _handleDioException(
    DioException e,
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool queueOffline = true,
  }) async {
    log('🌐 $method /$path response status code: ${e.message} ❌');
    
    // Check if request was cancelled
    if (e.type == DioExceptionType.cancel) {
      log('[ApiService] $method /$path request was cancelled');
      return ApiResponse.cancelled();
    }
    
    final apiResponse = ApiResponse.networkError(
      e.message ?? 'Unknown Dio error',
      statusCode: e.response?.statusCode ?? 0,
    );
    
    // If Dio exception occurs and offline queuing is enabled
    if (queueOffline && _isNetworkError(apiResponse)) {
      log('[ApiService] DioException occurred, queuing $method /$path: ${e.message}');
      await OfflineQueueService.queueRequest(
        method: method,
        endpoint: path,
        data: data ?? {},
      );
    }
    
    return apiResponse;
  }

  /// Handle generic exceptions with offline queuing
  static Future<ApiResponse> _handleException(
    Exception e,
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool queueOffline = true,
  }) async {
    log('🌐 $method /$path response status code: $e ❌');
    
    final apiResponse = ApiResponse.networkError(e.toString());
    
    // If exception occurs and offline queuing is enabled
    if (queueOffline) {
      log('[ApiService] Exception occurred, queuing $method /$path: $e');
      await OfflineQueueService.queueRequest(
        method: method,
        endpoint: path,
        data: data ?? {},
      );
    }
    
    return apiResponse;
  }
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
  /// [requestId] - Unique identifier for request cancellation (optional)
  /// [options] - Additional request options including timeout and cancel token
  /// 
  /// Returns [ApiResponse] with success status, data, or error information
  static Future<ApiResponse> post(
    String path, 
    Map<String, dynamic> body, {
    bool queueOffline = true,
    String? requestId,
    ApiOptions? options,
  }) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = _cleanBody(body);
      
      log('🌐 POST /$path $cleanedBody');

      // Build headers with common information
      final headers = await _buildHeaders();
      
      // Create cancel token if requestId provided
      final cancelToken = requestId != null ? _createCancelToken(requestId) : options?.cancelToken;

      // Send POST request using Dio
      final response = await dio.post(
        '/$path',
        data: cleanedBody,
        options: Options(
          headers: headers,
          receiveTimeout: options?.timeout ?? timeout,
        ),
        cancelToken: cancelToken,
      );

      final result = response.data as Map<String, dynamic>;

      // Check for successful HTTP status codes (200 OK or 201 Created)
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      log('🌐 POST /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse.success(result, response.statusCode!);
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse.error('create', path, response.statusCode!, result);
        
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
    } on DioException catch (e) {
      return await _handleDioException(e, 'POST', path, data: body, queueOffline: queueOffline);
    } catch (e) {
      return await _handleException(e as Exception, 'POST', path, data: body, queueOffline: queueOffline);
    }
  }

  /// Execute a PUT request with offline support
  static Future<ApiResponse> put(
    String path, 
    Map<String, dynamic> body, {
    bool queueOffline = true,
    String? requestId,
    ApiOptions? options,
  }) async {
    try {
      // Create a copy of body and remove timestamp fields
      final cleanedBody = _cleanBody(body);
      
      log('🌐 PUT /$path $cleanedBody');

      // Build headers with common information
      final headers = await _buildHeaders();
      
      // Create cancel token if requestId provided
      final cancelToken = requestId != null ? _createCancelToken(requestId) : options?.cancelToken;

      // Send PUT request using Dio
      final response = await dio.put(
        '/$path',
        data: cleanedBody,
        options: Options(
          headers: headers,
          receiveTimeout: options?.timeout ?? timeout,
        ),
        cancelToken: cancelToken,
      );

      final result = response.data as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK for PUT operations)
      final isSuccess = response.statusCode == 200;
      log('🌐 PUT /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse.success(result, response.statusCode!);
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse.error('update', path, response.statusCode!, result);
        
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
    } on DioException catch (e) {
      return await _handleDioException(e, 'PUT', path, data: body, queueOffline: queueOffline);
    } catch (e) {
      return await _handleException(e as Exception, 'PUT', path, data: body, queueOffline: queueOffline);
    }
  }

  /// Execute a DELETE request with offline support
  static Future<ApiResponse> delete(
    String path, {
    bool queueOffline = true,
    String? requestId,
    ApiOptions? options,
  }) async {
    try {
      log('🌐 DELETE /$path');

      // Build headers with common information
      final headers = await _buildHeaders();
      
      // Create cancel token if requestId provided
      final cancelToken = requestId != null ? _createCancelToken(requestId) : options?.cancelToken;

      // Send DELETE request using Dio
      final response = await dio.delete(
        '/$path',
        options: Options(
          headers: headers,
          receiveTimeout: options?.timeout ?? timeout,
        ),
        cancelToken: cancelToken,
      );

      final result = response.data as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK or 204 No Content for DELETE operations)
      final isSuccess = response.statusCode == 200 || response.statusCode == 204;
      log('🌐 DELETE /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse.success(result, response.statusCode!);
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse.error('delete', path, response.statusCode!, result);
        
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
    } on DioException catch (e) {
      return await _handleDioException(e, 'DELETE', path, data: {}, queueOffline: queueOffline);
    } catch (e) {
      return await _handleException(e as Exception, 'DELETE', path, data: {}, queueOffline: queueOffline);
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
    String? requestId,
  }) async {
    try {
      log('🌐 GET /$path${queryParams != null ? '?${Uri(queryParameters: queryParams).query}' : ''}');

      // Build headers with common information
      final headers = await _buildHeaders();
      log('🌐 GET headers: $headers');
      
      // Create cancel token if requestId provided
      final cancelToken = requestId != null ? _createCancelToken(requestId) : options?.cancelToken;

      // Send GET request using Dio with query parameters
      final response = await dio.get(
        '/$path',
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          receiveTimeout: options?.timeout ?? timeout,
        ),
        cancelToken: cancelToken,
      );

      final result = response.data as Map<String, dynamic>;

      // Check for successful HTTP status (200 OK for GET operations)
      final isSuccess = response.statusCode == 200;
      log('🌐 GET /$path response status code: ${response.statusCode} ${isSuccess ? '✅' : '⚠️'}');
      
      if (isSuccess) {
        // Parse the successful JSON response and return success result
        return ApiResponse.success(result, response.statusCode!);
      } else {
        // Handle HTTP error responses with status code information
        final apiResponse = ApiResponse.error('get', path, response.statusCode!, result);
        
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
    } on DioException catch (e) {
      return await _handleDioException(e, 'GET', path, data: queryParams ?? {}, queueOffline: queueOffline);
    } catch (e) {
      return await _handleException(e as Exception, 'GET', path, data: queryParams ?? {}, queueOffline: queueOffline);
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
