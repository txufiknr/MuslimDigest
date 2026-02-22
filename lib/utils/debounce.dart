import 'dart:async';
import 'package:flutter/widgets.dart';

/// Utility class for debouncing function calls
class Debounce {
  Timer? _timer;
  final Duration delay;

  Debounce(this.delay);

  /// Cancels any pending timer and schedules a new one
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels the current timer if active
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns true if there's a pending timer
  bool get isPending => _timer?.isActive ?? false;

  /// Disposes the debounce resources
  void dispose() {
    cancel();
  }
}

/// Extension method for easy debounce creation
extension DebounceExtension on Duration {
  Debounce get debounce => Debounce(this);
}
