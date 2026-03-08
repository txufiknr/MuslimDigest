import 'package:flutter/material.dart';
import 'timeago.dart';

/// Example implementations and usage patterns for Timeago library
class TimeagoExamples extends StatelessWidget {
  const TimeagoExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final testTimes = [
      now.subtract(const Duration(seconds: 10)),
      now.subtract(const Duration(minutes: 5)),
      now.subtract(const Duration(hours: 2)),
      now.subtract(const Duration(days: 1)),
      now.subtract(const Duration(days: 3)),
      now.subtract(const Duration(days: 14)), // 2 weeks
      now.subtract(const Duration(days: 60)), // ~2 months
      now.subtract(const Duration(days: 365)), // 1 year
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Timeago Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Static Formatting Examples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...testTimes.map((time) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pretty: ${TimeagoUtil.format(time)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Explicit: ${TimeagoUtil.format(time, config: const TimeagoConfig(explicit: true))}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 32),
          const Text(
            'Live Auto-Refresh Examples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ExampleCard(
            title: 'Basic Auto-Refresh',
            child: TimeagoWidget(dateTime: DateTime.now().subtract(const Duration(minutes: 1))),
          ),
          ExampleCard(
            title: 'Explicit Format',
            child: TimeagoWidget(
              dateTime: DateTime.now().subtract(const Duration(minutes: 1)),
              config: const TimeagoConfig(explicit: true),
            ),
          ),
          ExampleCard(
            title: 'Fast Update (10s)',
            child: TimeagoWidget(
              dateTime: DateTime.now().subtract(const Duration(seconds: 30)),
              config: TimeagoConfig(updateInterval: const Duration(seconds: 10)),
            ),
          ),
          ExampleCard(
            title: 'Custom Style',
            child: TimeagoWidget(
              dateTime: DateTime.now().subtract(const Duration(minutes: 2)),
              builder: (context, text) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Convenience Widgets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ExampleCard(
            title: 'TimeagoText',
            child: TimeagoText(
              dateTime: DateTime.now().subtract(const Duration(hours: 3)),
              explicit: false,
              style: TextStyle(color: Colors.green),
            ),
          ),
          ExampleCard(
            title: 'TimeagoCompact',
            child: TimeagoCompact(
              dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
              explicit: true,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for example cards
class ExampleCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ExampleCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Usage examples for different contexts
class TimeagoUsagePatterns {
  /// Social media post timestamp
  static Widget postTimestamp(DateTime createdAt) {
    return TimeagoCompact(
      dateTime: createdAt,
      explicit: true,
      fontSize: 12,
    );
  }

  /// Article publish date with more detail
  static Widget articleDate(DateTime publishedAt) {
    return TimeagoWidget(
      dateTime: publishedAt,
      config: const TimeagoConfig(explicit: false, updateInterval: Duration(seconds: 30)),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Chat message timestamp
  static Widget chatTimestamp(DateTime messageTime) {
    return TimeagoText(
      dateTime: messageTime,
      explicit: true,
      updateInterval: const Duration(minutes: 1),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.grey,
      ),
    );
  }

  /// Last seen indicator
  static Widget lastSeen(DateTime lastActive) {
    return TimeagoWidget(
      dateTime: lastActive,
      config: const TimeagoConfig(explicit: true, updateInterval: Duration(minutes: 1)),
      builder: (context, text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Active $text',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
