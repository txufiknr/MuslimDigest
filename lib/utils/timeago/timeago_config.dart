import 'package:muslimdigest/config/constants.dart';

/// Configuration for timeago formatting and behavior
class TimeagoConfig {
  /// Whether to use explicit format (e.g., "1m ago") vs pretty format (e.g., "a moment ago")
  final bool explicit;
  
  /// Update interval for auto-refresh widgets
  final Duration updateInterval;
  
  /// Locale for formatting (future expansion)
  final String locale;
  
  /// Custom thresholds for time formatting
  final TimeagoThresholds thresholds;

  const TimeagoConfig({
    this.explicit = false,
    this.updateInterval = const Duration(minutes: 1),
    this.locale = APP_LANGUAGE,
    this.thresholds = const TimeagoThresholds(),
  });

  TimeagoConfig copyWith({
    bool? explicit,
    Duration? updateInterval,
    String? locale,
    TimeagoThresholds? thresholds,
  }) {
    return TimeagoConfig(
      explicit: explicit ?? this.explicit,
      updateInterval: updateInterval ?? this.updateInterval,
      locale: locale ?? this.locale,
      thresholds: thresholds ?? this.thresholds,
    );
  }
}

/// Thresholds for different time formatting categories
class TimeagoThresholds {
  /// Threshold in seconds for "a moment ago" (default: 30 seconds)
  final int momentThreshold;
  
  /// Threshold in seconds for hour-based formatting (default: 3600 = 1 hour)
  final int hourThreshold;
  
  /// Threshold in seconds for day-based formatting (default: 86400 = 24 hours)
  final int dayThreshold;
  
  /// Threshold in seconds for week-based formatting (default: 604800 = 7 days)
  final int weekThreshold;
  
  /// Threshold in seconds for month-based formatting (default: 2592000 = 30 days)
  final int monthThreshold;
  
  /// Threshold in seconds for year-based formatting (default: 31536000 = 365 days)
  final int yearThreshold;

  const TimeagoThresholds({
    this.momentThreshold = 30,
    this.hourThreshold = 3600,
    this.dayThreshold = 86400,
    this.weekThreshold = 604800,
    this.monthThreshold = 2592000,
    this.yearThreshold = 31536000,
  });
}
