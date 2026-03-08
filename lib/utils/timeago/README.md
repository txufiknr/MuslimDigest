# Timeago Utility Library

A robust, feature-rich time formatting library for Flutter applications with auto-refresh capabilities and customizable formatting options.

## Features

- 🕐 **Smart Time Formatting**: Human-readable formats like "2h ago", "yesterday", "a moment ago"
- ⚡ **Auto-Refresh Widgets**: Live updating timestamps with configurable intervals
- 🎛️ **Flexible Configuration**: Support for both explicit ("1m ago") and pretty ("a moment ago") formats
- 🌍 **Internationalization Ready**: Extensible architecture for multiple languages
- 📱 **Multiple Widget Types**: Specialized widgets for different use cases
- ⚙️ **Customizable Thresholds**: Configurable time boundaries for different formats

## Quick Start

### Installation

Add the import to your Dart file:

```dart
import 'package:muslimdigest/utils/timeago/timeago.dart';
```

### Basic Usage

```dart
// Static formatting
final text = TimeagoUtil.format(DateTime.now().subtract(Duration(hours: 2)));
// Returns: "2 hours ago"

// Explicit format
final explicit = TimeagoUtil.format(
  DateTime.now().subtract(Duration(minutes: 5)),
  config: TimeagoConfig(explicit: true),
);
// Returns: "5m ago"
```

### Widget Usage

```dart
// Auto-refresh widget
TimeagoWidget(
  dateTime: article.publishedAt,
  config: TimeagoConfig(
    explicit: true,
    updateInterval: const Duration(seconds: 30),
  ),
)

// Convenience widget
TimeagoText(
  dateTime: comment.createdAt,
  explicit: true,
  style: TextStyle(color: Colors.grey),
)

// Compact widget for lists
TimeagoCompact(
  dateTime: post.createdAt,
  explicit: true,
  color: Colors.blue,
)
```

## API Reference

### TimeagoUtil

Static utility class for formatting time differences.

#### Methods

- `format(DateTime dateTime, {TimeagoConfig? config, DateTime? now})` → String
- `getTimeDifference(DateTime dateTime, {DateTime? now})` → int
- `isMomentAgo(DateTime dateTime, {TimeagoConfig? config})` → bool
- `isYesterday(DateTime dateTime, {DateTime? now})` → bool

### TimeagoConfig

Configuration class for customizing formatting behavior.

#### Properties

- `explicit` (bool): Use explicit format vs pretty format (default: false)
- `updateInterval` (Duration): Auto-refresh interval (default: Duration(minutes: 1))
- `locale` (String): Locale for formatting (default: APP_LANGUAGE)
- `thresholds` (TimeagoThresholds): Custom time thresholds

### TimeagoWidget

Stateful widget with auto-refresh capabilities.

#### Constructor

```dart
TimeagoWidget({
  required DateTime dateTime,
  TimeagoConfig config = const TimeagoConfig(),
  Widget Function(BuildContext, String)? builder,
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
})
```

### Convenience Widgets

#### TimeagoText

Simplified widget for common use cases.

```dart
TimeagoText(
  dateTime: someTime,
  explicit: false,
  updateInterval: const Duration(minutes: 1),
  style: someStyle,
)
```

#### TimeagoCompact

Optimized for tight spaces like list items.

```dart
TimeagoCompact(
  dateTime: someTime,
  explicit: true,
  color: Colors.blue,
  fontSize: 12,
)
```

## Time Thresholds

The library uses these default thresholds:

| Time Range | Pretty Format | Explicit Format |
|------------|---------------|-----------------|
| < 30 seconds | "a moment ago" | "0m ago" |
| < 1 hour | "X mins ago" | "Xm ago" |
| < 24 hours | "X hours ago" | "Xh ago" |
| < 7 days | "X days ago" / "yesterday" | "Xd ago" |
| < 30 days | "X weeks ago" | "Xw ago" |
| < 365 days | "X months ago" | "Xmo ago" |
| ≥ 365 days | "X years ago" | "Xy ago" |

## Custom Thresholds

You can customize the time boundaries:

```dart
TimeagoConfig(
  thresholds: TimeagoThresholds(
    momentThreshold: 60, // 1 minute for "moment"
    hourThreshold: 7200, // 2 hours before showing hours
  ),
)
```

## Use Case Examples

### Social Media Posts

```dart
Widget postTimestamp(Post post) {
  return TimeagoCompact(
    dateTime: post.createdAt,
    explicit: true,
    fontSize: 12,
  );
}
```

### Article Publish Dates

```dart
Widget articleDate(Article article) {
  return TimeagoWidget(
    dateTime: article.publishedAt,
    config: TimeagoConfig(explicit: false, updateInterval: 30),
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );
}
```

### Chat Messages

```dart
Widget chatTimestamp(Message message) {
  return TimeagoText(
    dateTime: message.timestamp,
    explicit: true,
    style: TextStyle(fontSize: 11, color: Colors.grey),
  );
}
```

### Custom Styled Timestamps

```dart
Widget customTimestamp(DateTime time) {
  return TimeagoWidget(
    dateTime: time,
    builder: (context, text) => Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  );
}
```

## Performance Considerations

- **Auto-Refresh**: Widgets use `Timer.periodic` for updates. Set appropriate intervals to balance freshness with battery usage.
- **Text Changes**: Widgets only rebuild when the formatted text actually changes, preventing unnecessary renders.
- **Memory Management**: Timers are automatically cancelled when widgets are disposed.

## Future Enhancements

- [ ] Multiple language support
- [ ] Custom date formatting (e.g., "Jan 15" instead of "2 days ago")
- [ ] Relative date formatting ("tomorrow at 3 PM")
- [ ] Calendar integration
- [ ] More granular time units (seconds, milliseconds)

## Examples

Run the example app to see all features in action:

```dart
import 'package:muslimdigest/utils/timeago/timeago_examples.dart';

// In your app:
MaterialApp(
  home: TimeagoExamples(),
)
```

## Contributing

Feel free to submit issues and enhancement requests!
