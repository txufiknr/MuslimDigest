import 'dart:async';
import 'package:flutter/material.dart';
import 'timeago_config.dart';
import 'timeago_util.dart';

/// A stateful widget that displays timeago text with auto-refresh capability
class TimeagoWidget extends StatefulWidget {
  /// The DateTime to display
  final DateTime dateTime;
  
  /// Configuration for formatting behavior
  final TimeagoConfig config;
  
  /// Optional custom builder for complete control over the widget
  final Widget Function(BuildContext context, String timeagoText)? builder;
  
  /// Optional text style
  final TextStyle? style;
  
  /// Optional text alignment
  final TextAlign? textAlign;
  
  /// Optional max lines for text wrapping
  final int? maxLines;
  
  /// Optional text overflow behavior
  final TextOverflow? overflow;

  const TimeagoWidget({
    super.key,
    required this.dateTime,
    this.config = const TimeagoConfig(),
    this.builder,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<TimeagoWidget> createState() => _TimeagoWidgetState();
}

class _TimeagoWidgetState extends State<TimeagoWidget> {
  Timer? _timer;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _updateText();
    _startTimer();
  }

  @override
  void didUpdateWidget(TimeagoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Restart timer if config changed
    if (oldWidget.config.updateInterval != widget.config.updateInterval) {
      _timer?.cancel();
      _startTimer();
    }
    
    // Update text if dateTime changed
    if (oldWidget.dateTime != widget.dateTime) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Only start timer if update interval is greater than 0
    if (widget.config.updateInterval.inMilliseconds > 0) {
      _timer = Timer.periodic(
        widget.config.updateInterval,
        (_) => _updateText(),
      );
    }
  }

  void _updateText() {
    if (!mounted) return;
    
    final newText = TimeagoUtil.format(
      widget.dateTime,
      config: widget.config,
    );
    
    // Only setState if text actually changed to avoid unnecessary rebuilds
    if (_currentText != newText) {
      setState(() {
        _currentText = newText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use custom builder if provided
    if (widget.builder != null) {
      return widget.builder!(context, _currentText);
    }
    
    // Default text widget
    return Text(
      _currentText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// A convenience widget for common timeago use cases
class TimeagoText extends StatelessWidget {
  /// The DateTime to display
  final DateTime dateTime;
  
  /// Whether to use explicit format
  final bool explicit;
  
  /// Update interval for auto-refresh
  final Duration updateInterval;
  
  /// Text style
  final TextStyle? style;
  
  /// Text alignment
  final TextAlign? textAlign;

  const TimeagoText({
    super.key,
    required this.dateTime,
    this.explicit = false,
    this.updateInterval = const Duration(minutes: 1),
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TimeagoWidget(
      dateTime: dateTime,
      config: TimeagoConfig(
        explicit: explicit,
        updateInterval: updateInterval,
      ),
      style: style,
      textAlign: textAlign,
    );
  }
}

/// A timeago widget specifically designed for list items and compact spaces
class TimeagoCompact extends StatelessWidget {
  /// The DateTime to display
  final DateTime dateTime;
  
  /// Whether to use explicit format (defaults to true for compact)
  final bool explicit;
  
  /// Text color
  final Color? color;
  
  /// Font size
  final double? fontSize;

  const TimeagoCompact({
    super.key,
    required this.dateTime,
    this.explicit = true,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TimeagoText(
      dateTime: dateTime,
      explicit: explicit,
      updateInterval: const Duration(minutes: 1),
      style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.end,
    );
  }
}
