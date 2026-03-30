/// Default timeout for API requests
const Duration API_REQUEST_TIMEOUT = Duration(seconds: 30);

/// HTTP content type for JSON requests
const String API_CONTENT_TYPE = 'application/json';

/// Known API endpoints for pattern detection and deduplication
class ApiEndpoints {
  /// Feed operations endpoints
  static const Set<String> feedEndpoints = {
    'feed/save',
    'feed/like', 
    'feed/not_interested',
    'feed/history',
    'feed/saved',
    'feed/collections',
    'feed/latest',
    'feed/digest',
    'feed/trending',
    'feed/feedback',
  };
  
  /// User operations endpoints
  static const Set<String> userEndpoints = {
    'user',
    'preferences',
    'user/reset',
  };
  
  /// All known endpoints
  static const Set<String> allEndpoints = {
    ...feedEndpoints,
    ...userEndpoints,
  };
}