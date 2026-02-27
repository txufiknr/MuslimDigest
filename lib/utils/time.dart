import 'package:jhijri/_src/_jHijri.dart';
import 'package:muslimdigest/variables/time.dart';

/// Check if two dates are the same day
bool isSameDay(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

/// Check if a date is today
bool isToday(DateTime date) {
  return isSameDay(date, today);
}

JHijri get hijriDate => JHijri.now();
bool get isRamadan => hijriDate.month == 9;

String getHijriDate() {
  
  // Format: Day Month Year (e.g., 27 Ramadan 1445 AH)
  final months = [
    'Muharram', 'Safar', 'Rabi\' al-awwal', 'Rabi\' al-thani',
    'Jumada al-awwal', 'Jumada al-thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
  ];
  
  return '${hijriDate.day} ${months[hijriDate.month - 1]} ${hijriDate.year} AH';
}