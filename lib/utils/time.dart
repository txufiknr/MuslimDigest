import 'package:flutter/material.dart';
import 'package:jhijri/_src/_jHijri.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/time.dart';

/// Check if two dates are the same day
bool isSameDay(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

/// Check if a date is today
bool isToday(DateTime? date) => isSameDay(date, today);

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

/// Check if it's Mawlid al-Nabi (12 Rabi' al-awwal)
bool get isMawlid => hijriDate.month == 3 && hijriDate.day == 12;

/// Check if it's Isra and Mi'raj (27 Rajab)
bool get isIsraMiraj => hijriDate.month == 7 && hijriDate.day == 27;

/// Check if it's Laylat al-Qadr (Night of Power, odd nights in last 10 days of Ramadan: 21, 23, 25, 27, 29)
bool get isLaylatAlQadr => hijriDate.month == 9 && 
    hijriDate.day >= 21 && 
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

/// Convert read time in seconds to user-friendly "n min read" format
String formatReadTime(double? readTimeSeconds) {
  if (readTimeSeconds == null || readTimeSeconds <= 0) {
    return '';
  }
  
  // Convert seconds to minutes, rounding up to nearest minute
  final minutes = (readTimeSeconds / 60).ceil();
  
  // Handle singular/plural
  if (minutes == 1) {
    return '1 min read';
  } else if (minutes < 60) {
    return '$minutes min read';
  } else {
    // For longer content, show hours
    final hours = (minutes / 60).ceil();
    if (hours == 1) {
      return '1 hour read';
    } else {
      return '$hours hours read';
    }
  }
}

/// Calculate approximate read time in seconds from text content
/// Based on average reading speed of 200-250 words per minute
/// Minimum read time is 100 words (~30 seconds)
double estimateReadTime(String? text, {int wordsPerMinute = 225}) {
  if (text == null || text.trim().isEmpty) {
    return 0.0;
  }
  
  // Clean the text: remove extra whitespace and count words
  final cleanText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final wordCount = cleanText.split(' ').length;
  
  // Calculate seconds needed, round up to nearest second
  final seconds = (wordCount / wordsPerMinute * 60).ceil().toDouble();
  
  // Ensure minimum of 100 words (~30 seconds) for any non-empty content
  final minimumSeconds = (100 / wordsPerMinute * 60).ceil().toDouble();
  return seconds > minimumSeconds ? seconds : minimumSeconds;
}

enum IslamicEvent {
  ramadan,
  laylat_al_qadr,
  eid_al_fitr,
  day_of_arafah,
  eid_al_adha,
  islamic_new_year,
  mawlid,
  isra_miraj;

  static IslamicEvent? fromString(String value) {
    return values.firstWhereOrNull((e) => e.name == value);
  }

  String get title {
    switch (this) {
      case eid_al_fitr: return 'Eid al-Fitr';
      case eid_al_adha: return 'Eid al-Adha';
      case islamic_new_year: return 'Islamic New Year';
      case day_of_arafah: return 'Day of Arafah';
      case laylat_al_qadr: return 'Laylat al-Qadr';
      case ramadan: return 'Ramadan';
      case mawlid: return 'Mawlid';
      case isra_miraj: return 'Isra Mi\'raj';
    }
  }

  String get subtitle {
    switch (this) {
      case eid_al_fitr:      return 'Celebration marking the end of Ramadan';
      case eid_al_adha:      return 'Festival of Sacrifice during Hajj';
      case islamic_new_year: return 'First day of the Islamic calendar';
      case day_of_arafah:    return 'Important day of worship during Hajj';
      case laylat_al_qadr:   return 'Night of Power in Ramadan';
      case ramadan:          return 'Holy month of fasting and reflection';
      case mawlid:           return 'Prophet Muhammad\'s birthday';
      case isra_miraj:       return 'Prophet Muhammad\'s night journey and ascension';
    }
  }

  String get emoji {
    switch (this) {
      case ramadan: return '🌙';
      case laylat_al_qadr: return '✨';
      case eid_al_fitr: return '🙏';
      case day_of_arafah: return '🕋';
      case eid_al_adha: return '🐐';
      case islamic_new_year: return '🌙';
      case mawlid: return '🕌';
      case isra_miraj: return '🌟';
    }
  }

  Color get color {
    switch (this) {
      case ramadan: return Colors.deepPurple;
      case laylat_al_qadr: return Colors.amber;
      case eid_al_fitr: return Colors.green;
      case day_of_arafah: return Colors.brown;
      case eid_al_adha: return Colors.orange;
      case islamic_new_year: return Colors.blue;
      case mawlid: return Colors.teal;
      case isra_miraj: return Colors.indigo;
    }
  }

  bool get isOngoing {
    switch (this) {
      case ramadan: return isRamadan;
      case laylat_al_qadr: return isLaylatAlQadr;
      case eid_al_fitr: return isEidAlFitr;
      case day_of_arafah: return isDayOfArafah;
      case eid_al_adha: return isEidAlAdha;
      case islamic_new_year: return isIslamicNewYear;
      case mawlid: return isMawlid;
      case isra_miraj: return isIsraMiraj;
    }
  }
}