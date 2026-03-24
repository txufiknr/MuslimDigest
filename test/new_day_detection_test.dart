import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/read_count.dart';

void main() {
  group('New Day Detection Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });

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

    test('New day detection with different timezones', () {
      // Test edge case around midnight UTC
      final utcNow = DateTime.utc(2024, 1, 1, 0, 30); // 12:30 AM UTC
      
      // Should still be considered "today" based on UTC comparison
      expect(isToday(utcNow), isTrue);
    });
  });

  group('Read Count Reset Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });

    test('Read count can be reset to zero', () async {
      final readCountNotifier = container.read(readCountProvider.notifier);
      
      // Set initial count
      await readCountNotifier.setValue(5);
      expect(container.read(readCountProvider), equals(5));
      
      // Reset to zero
      await readCountNotifier.setValue(0);
      expect(container.read(readCountProvider), equals(0));
    });

    test('Read count handles negative values', () async {
      final readCountNotifier = container.read(readCountProvider.notifier);
      
      // Try to set negative value
      await readCountNotifier.setValue(-5);
      expect(container.read(readCountProvider), equals(0)); // Should clamp to 0
    });
  });

  group('Ingest Last Date Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });

    test('Ingest last date can be set and retrieved', () async {
      final ingestDateNotifier = container.read(ingestLastDateProvider.notifier);
      final testDate = DateTime.now();
      
      // Set date
      await ingestDateNotifier.setValue(testDate);
      expect(container.read(ingestLastDateProvider), equals(testDate));
    });

    test('Ingest last date can be cleared', () async {
      final ingestDateNotifier = container.read(ingestLastDateProvider.notifier);
      
      // Set and clear date
      await ingestDateNotifier.setValue(DateTime.now());
      await ingestDateNotifier.clear();
      expect(container.read(ingestLastDateProvider), isNull);
    });
  });
}
