import 'package:flutter_test/flutter_test.dart';
import 'package:muslimdigest/services/notifications/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    test('generateNotificationId should produce unique IDs', () {
      final ids = <int>{};
      
      // Generate 100 IDs and ensure all are unique
      for (int i = 0; i < 100; i++) {
        final id = NotificationService.generateNotificationId();
        expect(ids.contains(id), false, reason: 'ID $id was duplicated');
        ids.add(id);
      }
      
      expect(ids.length, 100);
    });

    test('generateNotificationId should produce different IDs over time', () async {
      final id1 = NotificationService.generateNotificationId();
      
      // Wait a millisecond to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 1));
      
      final id2 = NotificationService.generateNotificationId();
      
      expect(id1, isNot(equals(id2)));
    });

    test('getRandomNotificationHour should return valid hours', () {
      for (int i = 0; i < 100; i++) {
        final hour = NotificationService.getRandomNotificationHour();
        expect(hour, greaterThanOrEqualTo(7));
        expect(hour, lessThanOrEqualTo(12));
      }
    });
  });
}
