/// YouTube utility functions for extracting video IDs and generating thumbnail URLs
library;

/// Extracts YouTube video ID from various URL formats
/// 
/// Supports:
/// - Standard: https://www.youtube.com/watch?v=VIDEO_ID
/// - Short: https://youtu.be/VIDEO_ID
/// - Embed: https://www.youtube.com/embed/VIDEO_ID
/// - Shortened: https://youtu.be/VIDEO_ID
/// 
/// Returns null if no valid video ID is found
String? extractVideoId(String? url) {
  if (url == null || url.isEmpty) return null;

  try {
    final uri = Uri.parse(url);
    
    // Handle youtu.be short URLs
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    
    // Handle youtube.com URLs
    if (uri.host.contains('youtube.com')) {
      // Check for /v/ path (embed URLs)
      if (uri.pathSegments.contains('v')) {
        final vIndex = uri.pathSegments.indexOf('v');
        if (vIndex + 1 < uri.pathSegments.length) {
          return uri.pathSegments[vIndex + 1];
        }
      }
      
      // Check for ?v= query parameter
      return uri.queryParameters['v'];
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

/// Generates YouTube thumbnail URL using the yt.img short URL format
/// 
/// Uses: https://yt.img/VIDEO_ID/maxresdefault.jpg
/// Returns null if videoId is null or empty
String? generateThumbnailUrl(String? videoId) {
  if (videoId == null || videoId.isEmpty) return null;
  
  return 'https://yt.img/$videoId/maxresdefault.jpg';
}

/// Validates if a URL is a YouTube URL
bool isYouTubeUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  
  try {
    final uri = Uri.parse(url);
    return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
  } catch (e) {
    return false;
  }
}

/// Checks if a YouTube video ID is valid (11 characters)
bool isValidVideoId(String? videoId) {
  if (videoId == null || videoId.isEmpty) return false;
  
  // YouTube video IDs are typically 11 characters long
  return videoId.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(videoId);
}
