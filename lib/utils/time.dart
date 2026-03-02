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

/// Get current hijri date
JHijri get hijriDate => JHijri.now();

/// Check if it's currently Ramadan
bool get isRamadan => hijriDate.month == 9;

/// Check if it's Eid al-Fitr (1 Shawwal)
bool get isEidAlFitr => hijriDate.month == 10 && hijriDate.day == 1;

/// Check if it's Eid al-Adha (10 Dhu al-Hijjah)  
bool get isEidAlAdha => hijriDate.month == 12 && hijriDate.day == 10;

/// Check if it's Islamic New Year (1 Muharram)
bool get isIslamicNewYear => hijriDate.month == 1 && hijriDate.day == 1;

/// Check if it's Day of Arafah (9 Dhu al-Hijjah)
bool get isDayOfArafah => hijriDate.month == 12 && hijriDate.day == 9;

/// Check if it's Laylat al-Qadr (Night of Power, odd nights in last 7 days of Ramadan: 23, 25, 27, 29)
bool get isLaylatAlQadr => hijriDate.month == 9 && 
    hijriDate.day >= 23 && 
    hijriDate.day <= 29 && 
    hijriDate.day % 2 == 1;

/// Check if it's the beginning of Hajj season (8 Dhu al-Hijjah)
bool get isHajjSeason => hijriDate.month == 12 && hijriDate.day >= 8 && hijriDate.day <= 13;

/// Get current hijri date (formatted)
String getHijriDate() {
  
  // Format: Day Month Year (e.g., 27 Ramadan 1445 AH)
  final months = [
    'Muharram', 'Safar', 'Rabi\' al-awwal', 'Rabi\' al-thani',
    'Jumada al-awwal', 'Jumada al-thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
  ];
  
  return '${hijriDate.day} ${months[hijriDate.month - 1]} ${hijriDate.year} AH';
}

enum IslamicEvent {
  EidAlFitr,
  EidAlAdha,
  IslamicNewYear,
  DayOfArafah,
  LaylatAlQadr,
  Ramadan;

  /// Get current Islamic event if any
  static List<IslamicEvent> get currentIslamicEvent => values.where((e) => e.isOngoing).toList();

  String get title {
    switch (this) {
      case EidAlFitr: return 'Eid al-Fitr';
      case EidAlAdha: return 'Eid al-Adha';
      case IslamicNewYear: return 'Islamic New Year';
      case DayOfArafah: return 'Day of Arafah';
      case LaylatAlQadr: return 'Laylat al-Qadr';
      case Ramadan: return 'Ramadan';
    }
  }

  String get subtitle {
    switch (this) {
      case EidAlFitr:      return 'Celebration marking the end of Ramadan';
      case EidAlAdha:      return 'Festival of Sacrifice during Hajj';
      case IslamicNewYear: return 'First day of the Islamic calendar';
      case DayOfArafah:    return 'Important day of worship during Hajj';
      case LaylatAlQadr:   return 'Night of Power in Ramadan';
      case Ramadan:        return 'Holy month of fasting and reflection';
    }
  }

  String get emoji {
    switch (this) {
      case EidAlFitr:      return '🙏';
      case EidAlAdha:      return '🐐';
      case IslamicNewYear: return '🌙';
      case DayOfArafah:    return '🕋';
      case LaylatAlQadr:   return '✨';
      case Ramadan:        return '🌙';
    }
  }

  List<String> get keywords {
    switch (this) {
      case EidAlFitr:      return ['eid', 'fitr', 'celebration', 'festival', 'breaking fast'];
      case EidAlAdha:      return ['eid', 'adha', 'sacrifice', 'hajj', 'ibrahim', 'islamic'];
      case IslamicNewYear: return ['islamic', 'new year', 'hijri', 'muharram', 'calendar'];
      case DayOfArafah:    return ['arafah', 'arafat', 'hajj', 'mount', 'worship', 'forgiveness'];
      case LaylatAlQadr:   return ['laylat', 'qadr', 'power', 'destiny', 'night', 'ramadan'];
      case Ramadan:        return ['ramadan', 'fasting', 'iftar', 'suhur', 'holy month'];
    }
  }

  bool get isOngoing {
    switch (this) {
      case EidAlFitr:      return isEidAlFitr;
      case EidAlAdha:      return isEidAlAdha;
      case IslamicNewYear: return isIslamicNewYear;
      case DayOfArafah:    return isDayOfArafah;
      case LaylatAlQadr:   return isLaylatAlQadr;
      case Ramadan:        return isRamadan;
    }
  }
}