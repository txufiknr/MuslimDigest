/// Timeago utility library for human-readable time formatting
/// 
/// This library provides:
/// - Static utility functions for time formatting
/// - Auto-refresh widgets for live updates
/// - Configurable formatting options
/// - Support for both explicit and pretty formats
/// 
/// Example usage:
/// ```dart
/// // Static formatting
/// final text = TimeagoUtil.format(DateTime.now().subtract(Duration(hours: 2)));
/// // Returns: "2 hours ago" or "2h ago" if explicit=true
/// 
/// // Auto-refresh widget
/// TimeagoWidget(
///   dateTime: article.publishedAt,
///   config: TimeagoConfig(explicit: true, updateInterval: 30),
/// )
/// 
/// // Compact widget for lists
/// TimeagoCompact(dateTime: comment.createdAt)
/// ```
library;

export 'timeago_config.dart';
export 'timeago_util.dart';
export 'timeago_widget.dart';
