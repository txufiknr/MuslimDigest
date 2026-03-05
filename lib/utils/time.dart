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

/// Utility class for Islamic event content matching and scoring
class IslamicEventMatcher {
  /// Find the best matching Islamic event for given content
  static IslamicEvent? findBestMatch({
    required String title,
    String? videoTitle,
    required String summary,
    String? topic,
  }) {
    if (title.isEmpty && (videoTitle?.isEmpty ?? true) && summary.isEmpty && (topic?.isEmpty ?? true)) {
      return null;
    }
    
    IslamicEvent? bestEvent;
    double bestScore = 0.0;
    
    for (final event in IslamicEvent.values) {
      final score = _calculateEventScore(
        event: event,
        title: title,
        videoTitle: videoTitle,
        summary: summary,
        topic: topic,
      );
      if (score > bestScore) {
        bestScore = score;
        bestEvent = event;
      }
    }
    
    // Only return event if it has a meaningful score
    return bestScore > 3.0 ? bestEvent : null;
  }

  /// Calculate keyword match score for an IslamicEvent
  static double _calculateEventScore({
    required IslamicEvent event,
    required String title,
    String? videoTitle,
    required String summary,
    String? topic,
  }) {
    final contentFields = [
      {'content': title, 'weight': 3.0},
      if (videoTitle != null) {'content': videoTitle, 'weight': 2.5},
      {'content': summary, 'weight': 2.0},
      if (topic != null) {'content': topic, 'weight': 1.0},
    ];

    double totalScore = 0.0;
    
    for (final field in contentFields) {
      final content = field['content'] as String;
      final weight = field['weight'] as double;
      
      // Check for exact phrase matches (highest score)
      for (final keyword in event.keywords) {
        if (content.toLowerCase().contains(keyword.toLowerCase())) {
          // Higher score for exact phrase matches
          totalScore += weight * 5.0;
          
          // Bonus for longer keywords (more specific)
          totalScore += keyword.length * 0.5 * weight;
          
          // Extra bonus for multi-word phrases (more specific)
          if (keyword.contains(' ')) {
            totalScore += weight * 3.0;
          }
          
          // Super bonus for unique identifying keywords
          if (_isUniqueKeyword(keyword, event)) {
            totalScore += weight * 10.0;
          }
        }
      }
      
      // Check individual word matches with context awareness
      final contentWords = content.toLowerCase().split(RegExp(r'\s+'));
      for (final keyword in event.keywords) {
        final keywordWords = keyword.toLowerCase().split(RegExp(r'\s+'));
        
        for (final kwWord in keywordWords) {
          // Skip very common words that could create false positives
          if (_isCommonWord(kwWord)) continue;
          
          if (contentWords.contains(kwWord)) {
            totalScore += weight * 0.8;
          }
        }
      }
    }
    
    // Specificity bonus: prefer more specific events over general ones
    switch (event) {
      case IslamicEvent.LaylatAlQadr:
        totalScore += 2.0; // Most specific
        break;
      case IslamicEvent.DayOfArafah:
      case IslamicEvent.EidAlFitr:
      case IslamicEvent.EidAlAdha:
        totalScore += 1.5; // Specific events
        break;
      case IslamicEvent.IslamicNewYear:
        totalScore += 1.0; // Moderately specific
        break;
      case IslamicEvent.Ramadan:
        totalScore += 0.5; // General month
        break;
    }
    
    return totalScore;
  }

  /// Filter out common words that could create false positives
  static bool _isCommonWord(String word) {
    const commonWords = {
      'night', 'power', 'day', 'month', 'year', 'time', 'holy', 'new', 'islamic', 'date', 'updates'
    };
    return commonWords.contains(word);
  }

  /// Check if a keyword is unique to a specific event
  static bool _isUniqueKeyword(String keyword, IslamicEvent event) {
    switch (event) {
      case IslamicEvent.EidAlAdha:
        return ['adha', 'sacrifice', 'ibrahim'].contains(keyword.toLowerCase());
      case IslamicEvent.EidAlFitr:
        return ['fitr', 'breaking fast'].contains(keyword.toLowerCase());
      case IslamicEvent.LaylatAlQadr:
        return ['laylat', 'qadr', 'destiny'].contains(keyword.toLowerCase());
      case IslamicEvent.DayOfArafah:
        return ['arafah', 'arafat', 'forgiveness'].contains(keyword.toLowerCase());
      case IslamicEvent.IslamicNewYear:
        return ['hijri', 'muharram'].contains(keyword.toLowerCase());
      case IslamicEvent.Ramadan:
        return ['iftar', 'suhur'].contains(keyword.toLowerCase());
    }
  }
}