// Test file to understand NotificationCalendar repeat behavior
// This is documentation to clarify how repeats: true works

/*
NOTIFICATIONCALENDAR REPEAT BEHAVIOR ANALYSIS:

When you specify exact date components (year, month, day) with repeats: true:

1. ALL SPECIFIED FIELDS ARE LOCKED:
   - If you specify year=2024, month=12, day=25, hour=9, minute=0
   - The notification will ONLY fire on Dec 25, 2024 at 9:00 AM
   - With repeats: true, it will fire EVERY YEAR on Dec 25 at 9:00 AM

2. PARTIAL SPECIFICATION:
   - If you specify month=12, day=25, hour=9, minute=0 (no year)
   - The notification will fire EVERY YEAR on Dec 25 at 9:00 AM
   - With repeats: true, it continues this annual pattern

3. OUR CURRENT IMPLEMENTATION:
   - We specify: year=2024, month=12, day=25, hour=randomHour
   - Result: Fires on Dec 25, 2024 at randomHour, then repeats annually on Dec 25
   - NOT what we want! We want daily rotation.

THE PROBLEM:
Our current implementation creates ANNUAL notifications, not daily rotation.
Each notification fires once per year on its specific date.

SOLUTION OPTIONS:
1. Don't specify year/month/day - only specify hour/minute for daily repeat
2. Use a different approach with multiple one-time notifications
3. Create a daily repeating notification that changes content dynamically

RECOMMENDED APPROACH:
Create ONE daily repeating notification and change content dynamically
when the notification is triggered, not when scheduled.
*/

import 'package:awesome_notifications/awesome_notifications.dart';

// Example of correct daily repeat:
void scheduleCorrectDailyNotification() {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1001,
      channelKey: 'daily_reminder',
      title: 'Daily Islamic Reminder',
      body: 'Open Muslim Digest for today\'s inspiration',
    ),
    schedule: NotificationCalendar(
      hour: 9,           // Only specify time, no date
      minute: 0,
      second: 0,
      repeats: true,    // This will repeat DAILY at 9:00 AM
      allowWhileIdle: true,
      timeZone: 'UTC',
    ),
  );
}

// Example of annual repeat (our current wrong approach):
void scheduleAnnualNotification() {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1002,
      channelKey: 'daily_reminder',
      title: 'Annual Islamic Reminder',
      body: 'This fires once per year!',
    ),
    schedule: NotificationCalendar(
      year: 2024,       // Specifying year locks it to annual repeat
      month: 12,
      day: 25,
      hour: 9,
      minute: 0,
      second: 0,
      repeats: true,    // This repeats ANNUALLY on Dec 25
      allowWhileIdle: true,
      timeZone: 'UTC',
    ),
  );
}
