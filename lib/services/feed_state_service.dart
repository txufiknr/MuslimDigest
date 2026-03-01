import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/variables/feed.dart';

/// Utility functions for feed state management
class FeedStateService {
  /// Execute an operation on all feed type notifiers
  static Future<void> executeOnAllFeedTypes(
    WidgetRef ref,
    Future<void> Function(BaseFeedNotifier notifier) operation,
  ) async {
    for (final feedType in FeedType.values) {
      await operation(feedType.getNotifier(ref));
    }
  }

  /// Mark feed as not interested across all feed types
  static Future<void> markNotInterestedEverywhere(
    WidgetRef ref,
    String feedId, {
    FeedbackCategory? reason,
  }) async {
    await executeOnAllFeedTypes(ref, (notifier) {
      return notifier.markAsNotInterested(feedId, reason: reason);
    });
  }

  /// Unmark feed as not interested across all feed types
  static Future<void> unmarkNotInterestedEverywhere(
    WidgetRef ref,
    String feedId,
  ) async {
    await executeOnAllFeedTypes(ref, (notifier) {
      return notifier.unmarkAsNotInterested(feedId);
    });
  }

  /// Check if feed should be hidden (SSOT logic)
  static bool shouldHideFeed(
    WidgetRef ref,
    String feedId,
    String sourceId,
  ) {
    final preferences = ref.watch(preferencesProvider);
    final isSourceAvoided = preferences.avoidedSources.contains(sourceId);
    
    // Check any feed type for not interested status
    final isNotInterested = FeedType.values.any((feedType) {
      return feedType.watch(ref).isNotInterested(feedId);
    });
    
    return isNotInterested || isSourceAvoided;
  }

  /// Get not interested reason from any feed type
  static FeedbackCategory? getNotInterestedReason(WidgetRef ref, String feedId) {
    for (final feedType in FeedType.values) {
      final reason = feedType.getNotifier(ref).getNotInterestedReason(feedId);
      if (reason != null) return reason;
    }
    return null;
  }

  /// Safe API execution with consistent error handling
  static Future<T?> safeApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall,
    String successMessage, {
    String? errorMessage,
  }) async {
    try {
      final result = await apiCall();
      if (context.mounted) {
        showSnackBarSuccess(context, successMessage);
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        showSnackBarError(context, errorMessage ?? "Operation failed: $e");
      }
      return null;
    }
  }
}
