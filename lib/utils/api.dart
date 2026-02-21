import 'dart:math' show pow;
import 'dart:developer' show log;

/// Retry failed API requests with exponential backoff
/// 
/// [operation] - The async operation to retry
/// [maxRetries] - Maximum number of retry attempts (default: 3)
/// [initialDelay] - Initial delay before first retry in milliseconds (default: 1000)
/// [backoffMultiplier] - Multiplier for exponential backoff (default: 2.0)
/// 
/// Returns the result of the operation if successful, throws the last error if all retries fail
Future<T> retryWithBackOff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  int initialDelay = 1000,
  double backoffMultiplier = 2.0,
}) async {
  int attempt = 0;
  Exception? lastException;

  while (attempt <= maxRetries) {
    try {
      return await operation();
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      attempt++;
      
      if (attempt > maxRetries) {
        log('[retryWithBackOff] All $maxRetries attempts failed for operation: $lastException');
        rethrow;
      }
      
      // Calculate delay with exponential backoff
      final delay = initialDelay * pow(backoffMultiplier, attempt - 1);
      log('[retryWithBackOff] Attempt $attempt failed, retrying in ${delay}ms: $lastException');
      
      await Future.delayed(Duration(milliseconds: delay.round()));
    }
  }
  
  throw lastException!;
}