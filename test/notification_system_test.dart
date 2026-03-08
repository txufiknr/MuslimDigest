import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/services/notification_service.dart';
import 'package:muslimdigest/config/notification_config.dart';

void main() {
  group('Notification System Tests', () {
    test('Generate date-based ID', () {
      final id = NotificationService.generateDateBasedId();
      expect(id, isA<int>());
      expect(id, greaterThan(0));
      
      // Test with specific date
      final specificDate = DateTime(2024, 3, 15);
      final specificId = NotificationService.generateDateBasedId(specificDate);
      expect(specificId, equals(20240315));
    });

    test('Get random notification hour', () {
      final hour = NotificationService.getRandomNotificationHour();
      expect(hour, isA<int>());
      expect(hour, greaterThanOrEqualTo(7));
      expect(hour, lessThanOrEqualTo(12));
    });

    test('Notification config constants', () {
      expect(NotificationConfig.dailyReminderChannelKey, equals('daily_reminder'));
      expect(NotificationConfig.testChannelKey, equals('test_notifications'));
      expect(NotificationConfig.islamicRemindersGroupKey, equals('islamic_reminders'));
    });

    test('Action buttons configuration', () {
      final actions = NotificationConfig.getDailyReminderActions();
      expect(actions.length, equals(2));
      expect(actions[0].key, equals('OPEN_APP'));
      expect(actions[1].key, equals('SHARE'));
    });

    test('Daily reminder content creation', () {
      final content = NotificationConfig.getDailyReminderContent(
        id: 20240315,
        title: 'Test App',
        body: 'Test message',
      );
      
      expect(content.id, equals(20240315));
      expect(content.title, equals('Test App'));
      expect(content.body, equals('Test message'));
      expect(content.channelKey, equals('daily_reminder'));
      expect(content.notificationLayout, equals(NotificationLayout.BigText));
    });

    test('Daily schedule creation', () {
      final schedule = NotificationConfig.getDailySchedule(hour: 9);
      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
      expect(schedule.repeats, equals(true));
      expect(schedule.preciseAlarm, equals(true));
    });

    test('Channel groups configuration', () {
      final groups = NotificationConfig.channelGroups;
      expect(groups.length, equals(1));
      expect(groups[0].channelGroupKey, equals('islamic_reminders'));
      expect(groups[0].channelGroupName, equals('Islamic Reminders'));
    });

    test('Channels configuration', () {
      final channels = NotificationConfig.channels;
      expect(channels.length, equals(2));
      
      final dailyChannel = channels.firstWhere(
        (c) => c.channelKey == 'daily_reminder',
      );
      expect(dailyChannel.channelGroupKey, equals('islamic_reminders'));
      expect(dailyChannel.importance, equals(NotificationImportance.High));
      
      final testChannel = channels.firstWhere(
        (c) => c.channelKey == 'test_notifications',
      );
      expect(testChannel.channelGroupKey, equals('islamic_reminders'));
      expect(testChannel.importance, equals(NotificationImportance.Default));
    });
  });
}
