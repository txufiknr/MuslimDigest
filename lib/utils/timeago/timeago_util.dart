import 'timeago_config.dart';

/// Utility class for formatting time differences in human-readable format
class TimeagoUtil {
  /// Format a DateTime as a timeago string
  /// 
  /// [dateTime] The DateTime to format
  /// [config] Optional configuration for formatting behavior
  /// [now] Optional reference time (defaults to current time)
  static String format(
    DateTime dateTime, {
    TimeagoConfig? config,
    DateTime? now,
  }) {
    final cfg = config ?? const TimeagoConfig();
    final reference = now ?? DateTime.now();
    final difference = reference.difference(dateTime);
    
    // Handle future times
    if (difference.isNegative) {
      return _formatFuture(difference.inSeconds.abs(), cfg);
    }
    
    // Handle past times
    return _formatPast(difference.inSeconds, cfg);
  }

  /// Format past time differences
  static String _formatPast(int seconds, TimeagoConfig config) {
    final thresholds = config.thresholds;
    
    if (seconds < thresholds.momentThreshold) {
      return config.explicit ? '0m ago' : 'a moment ago';
    }
    
    if (seconds < thresholds.hourThreshold) {
      final minutes = (seconds / 60).floor();
      return config.explicit ? '${minutes}m ago' : _formatMinutes(minutes);
    }
    
    if (seconds < thresholds.dayThreshold) {
      final hours = (seconds / thresholds.hourThreshold).floor();
      return config.explicit ? '${hours}h ago' : _formatHours(hours);
    }
    
    if (seconds < thresholds.weekThreshold) {
      final days = (seconds / thresholds.dayThreshold).floor();
      return config.explicit ? '${days}d ago' : _formatDays(days);
    }
    
    if (seconds < thresholds.monthThreshold) {
      final weeks = (seconds / thresholds.weekThreshold).floor();
      return config.explicit ? '${weeks}w ago' : _formatWeeks(weeks);
    }
    
    if (seconds < thresholds.yearThreshold) {
      final months = (seconds / thresholds.monthThreshold).floor();
      return config.explicit ? '${months}mo ago' : _formatMonths(months);
    }
    
    final years = (seconds / thresholds.yearThreshold).floor();
    return config.explicit ? '${years}y ago' : _formatYears(years);
  }

  /// Format future time differences
  static String _formatFuture(int seconds, TimeagoConfig config) {
    final thresholds = config.thresholds;
    
    if (seconds < thresholds.momentThreshold) {
      return config.explicit ? 'in 0m' : 'in a moment';
    }
    
    if (seconds < thresholds.hourThreshold) {
      final minutes = (seconds / 60).floor();
      return config.explicit ? 'in ${minutes}m' : 'in ${_formatMinutes(minutes).replaceFirst(' ago', '')}';
    }
    
    if (seconds < thresholds.dayThreshold) {
      final hours = (seconds / thresholds.hourThreshold).floor();
      return config.explicit ? 'in ${hours}h' : 'in ${_formatHours(hours).replaceFirst(' ago', '')}';
    }
    
    if (seconds < thresholds.weekThreshold) {
      final days = (seconds / thresholds.dayThreshold).floor();
      return config.explicit ? 'in ${days}d' : 'in ${_formatDays(days).replaceFirst(' ago', '')}';
    }
    
    if (seconds < thresholds.monthThreshold) {
      final weeks = (seconds / thresholds.weekThreshold).floor();
      return config.explicit ? 'in ${weeks}w' : 'in ${_formatWeeks(weeks).replaceFirst(' ago', '')}';
    }
    
    if (seconds < thresholds.yearThreshold) {
      final months = (seconds / thresholds.monthThreshold).floor();
      return config.explicit ? 'in ${months}mo' : 'in ${_formatMonths(months).replaceFirst(' ago', '')}';
    }
    
    final years = (seconds / thresholds.yearThreshold).floor();
    return config.explicit ? 'in ${years}y' : 'in ${_formatYears(years).replaceFirst(' ago', '')}';
  }

  /// Pretty format for minutes
  static String _formatMinutes(int minutes) {
    if (minutes == 1) return '1 min ago';
    return '$minutes mins ago';
  }

  /// Pretty format for hours
  static String _formatHours(int hours) {
    if (hours == 1) return '1 hour ago';
    return '$hours hours ago';
  }

  /// Pretty format for days
  static String _formatDays(int days) {
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }

  /// Pretty format for weeks
  static String _formatWeeks(int weeks) {
    if (weeks == 1) return '1 week ago';
    return '$weeks weeks ago';
  }

  /// Pretty format for months
  static String _formatMonths(int months) {
    if (months == 1) return '1 month ago';
    return '$months months ago';
  }

  /// Pretty format for years
  static String _formatYears(int years) {
    if (years == 1) return '1 year ago';
    return '$years years ago';
  }

  /// Get the raw time difference in seconds
  static int getTimeDifference(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return reference.difference(dateTime).inSeconds;
  }

  /// Check if a DateTime is within the last moment threshold
  static bool isMomentAgo(DateTime dateTime, {TimeagoConfig? config}) {
    final cfg = config ?? const TimeagoConfig();
    final seconds = getTimeDifference(dateTime);
    return seconds >= 0 && seconds < cfg.thresholds.momentThreshold;
  }

  /// Check if a DateTime is yesterday
  static bool isYesterday(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(dateTime, yesterday);
  }

  /// Check if two DateTimes are on the same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
