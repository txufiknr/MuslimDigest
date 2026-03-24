import 'package:flutter_test/flutter_test.dart';
import 'package:muslimdigest/utils/time.dart';

void main() {
  group('New Day Detection Simple Tests', () {
    test('isToday returns true for current date', () {
      final now = DateTime.now();
      expect(isToday(now), isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(isToday(yesterday), isFalse);
    });

    test('isToday returns false for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(isToday(tomorrow), isFalse);
    });

    test('isToday handles null date', () {
      expect(isToday(null), isFalse);
    });

    test('isToday works with UTC dates', () {
      final utcNow = DateTime.now().toUtc();
      expect(isToday(utcNow), isTrue);
    });

    test('isSameDay works correctly', () {
      final date1 = DateTime(2024, 1, 15, 10, 30);
      final date2 = DateTime(2024, 1, 15, 22, 45);
      final date3 = DateTime(2024, 1, 16, 10, 30);
      
      expect(isSameDay(date1, date2), isTrue);
      expect(isSameDay(date1, date3), isFalse);
    });

    test('isSameDay works with UTC dates', () {
      final utcDate1 = DateTime.utc(2024, 1, 15, 10, 30);
      final utcDate2 = DateTime.utc(2024, 1, 15, 22, 45);
      final localDate = DateTime(2024, 1, 15, 10, 30);
      
      expect(isSameDay(utcDate1, utcDate2), isTrue);
      expect(isSameDay(utcDate1, localDate), isTrue);
    });

    test('New day detection around midnight UTC', () {
      // Test edge case around midnight UTC
      final beforeMidnight = DateTime.utc(2024, 1, 1, 23, 30);
      final afterMidnight = DateTime.utc(2024, 1, 2, 0, 30);
      
      // Should be different days
      expect(isSameDay(beforeMidnight, afterMidnight), isFalse);
    });

    test('Time helper functions work correctly', () {
      // Test that we can create dates and compare them
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      
      expect(isToday(today), isTrue);
      expect(isToday(yesterday), isFalse);
      expect(isToday(tomorrow), isFalse);
    });
  });
}
