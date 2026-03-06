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

  List<WeightedKeyword> get weightedKeywords {
    switch (this) {
      case EidAlFitr:      
        return [
          WeightedKeyword('eid', KeywordWeight.strong),
          WeightedKeyword('fitr', KeywordWeight.strong),
          WeightedKeyword('celebration', KeywordWeight.medium),
          WeightedKeyword('festival', KeywordWeight.medium),
          WeightedKeyword('breaking fast', KeywordWeight.strong),
        ];
      case EidAlAdha:      
        return [
          WeightedKeyword('eid', KeywordWeight.strong),
          WeightedKeyword('adha', KeywordWeight.strong),
          WeightedKeyword('sacrifice', KeywordWeight.strong),
          WeightedKeyword('qurban', KeywordWeight.strong),
          WeightedKeyword('ibrahim', KeywordWeight.strong),
        ];
      case IslamicNewYear: 
        return [
          WeightedKeyword('islamic', KeywordWeight.weak),
          WeightedKeyword('new year', KeywordWeight.medium),
          WeightedKeyword('hijri', KeywordWeight.strong),
          WeightedKeyword('muharram', KeywordWeight.strong),
          WeightedKeyword('calendar', KeywordWeight.weak),
        ];
      case DayOfArafah:    
        return [
          WeightedKeyword('arafah', KeywordWeight.strong),
          WeightedKeyword('arafat', KeywordWeight.strong),
          WeightedKeyword('hajj', KeywordWeight.medium),
          WeightedKeyword('mount', KeywordWeight.medium),
          WeightedKeyword('worship', KeywordWeight.medium),
          WeightedKeyword('forgiveness', KeywordWeight.medium),
        ];
      case LaylatAlQadr:   
        return [
          WeightedKeyword('laylat', KeywordWeight.strong),
          WeightedKeyword('qadr', KeywordWeight.strong),
          WeightedKeyword('power', KeywordWeight.medium),
          WeightedKeyword('destiny', KeywordWeight.strong),
          WeightedKeyword('night', KeywordWeight.weak),
          WeightedKeyword('odd nights', KeywordWeight.strong),
        ];
      case Ramadan:        
        return [
          WeightedKeyword('ramadan', KeywordWeight.strong),
          WeightedKeyword('fasting', KeywordWeight.strong),
          WeightedKeyword('iftar', KeywordWeight.strong),
          WeightedKeyword('suhur', KeywordWeight.strong),
          WeightedKeyword('holy month', KeywordWeight.medium),
        ];
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

/// Keyword weight categories for scoring precision
enum KeywordWeight {
  weak(1.0),
  medium(1.5),
  strong(2.0);

  const KeywordWeight(this.multiplier);
  final double multiplier;
}

/// Weighted keyword with strength classification
class WeightedKeyword {
  final String keyword;
  final KeywordWeight weight;
  
  const WeightedKeyword(this.keyword, this.weight);
  
  double get scoreMultiplier => weight.multiplier;
}

/// Utility class for keyword detection and counting
class KeywordMatcher {
  /// Count occurrences of a keyword in content (case-insensitive)
  static int countOccurrences(String content, String keyword) {
    if (keyword.isEmpty || content.isEmpty) return 0;
    
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    
    int count = 0;
    int index = 0;
    
    while (true) {
      index = lowerContent.indexOf(lowerKeyword, index);
      if (index == -1) break;
      
      count++;
      index += lowerKeyword.length;
    }
    
    return count;
  }
  
  /// Calculate keyword score based on weighted keywords and content
  static double calculateKeywordScore(String content, List<WeightedKeyword> weightedKeywords) {
    double totalScore = 0.0;
    
    for (final weightedKeyword in weightedKeywords) {
      final occurrences = countOccurrences(content, weightedKeyword.keyword);
      
      if (occurrences > 0) {
        // Base score for finding the keyword
        double keywordScore = 5.0 * weightedKeyword.scoreMultiplier;
        
        // Bonus for multiple occurrences
        keywordScore += (occurrences - 1) * 2.0 * weightedKeyword.scoreMultiplier;
        
        // Bonus for longer keywords (more specific)
        keywordScore += weightedKeyword.keyword.length * 0.5 * weightedKeyword.scoreMultiplier;
        
        // Extra bonus for multi-word phrases (more specific)
        if (weightedKeyword.keyword.contains(' ')) {
          keywordScore += 3.0 * weightedKeyword.scoreMultiplier;
        }
        
        totalScore += keywordScore;
      }
    }
    
    return totalScore;
  }
  
  /// Check if a keyword is unique to a specific event
  static bool isUniqueKeyword(String keyword, IslamicEvent event) {
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
  
  /// Filter out common words that could create false positives
  static bool isCommonWord(String word) {
    const commonWords = {
      'night', 'power', 'day', 'month', 'year', 'time', 'holy', 'new', 'islamic', 'date', 'updates'
    };
    return commonWords.contains(word);
  }
}

/// Utility class for calculating event scores
class ScoreCalculator {
  /// Calculate comprehensive score for an Islamic event
  static double calculateEventScore({
    required IslamicEvent event,
    required String title,
    String? videoTitle,
    required String summary,
    String? topic,
    bool isOngoing = false,
  }) {
    final contentFields = [
      {'content': title, 'weight': 3.0},
      if (videoTitle != null) {'content': videoTitle, 'weight': 2.5},
      {'content': summary, 'weight': 2.0},
      if (topic != null) {'content': topic, 'weight': 1.0},
    ];

    double totalScore = 0.0;
    
    // Calculate keyword-based scores for each content field
    for (final field in contentFields) {
      final content = field['content'] as String;
      final weight = field['weight'] as double;
      
      // Score from weighted keywords
      final keywordScore = KeywordMatcher.calculateKeywordScore(content, event.weightedKeywords);
      totalScore += keywordScore * weight;
      
      // Bonus for unique identifying keywords
      for (final weightedKeyword in event.weightedKeywords) {
        if (KeywordMatcher.countOccurrences(content, weightedKeyword.keyword) > 0) {
          if (KeywordMatcher.isUniqueKeyword(weightedKeyword.keyword, event)) {
            totalScore += weight * 10.0 * weightedKeyword.scoreMultiplier;
          }
        }
      }
      
      // Check individual word matches with context awareness
      final contentWords = content.toLowerCase().split(RegExp(r'\s+'));
      for (final weightedKeyword in event.weightedKeywords) {
        final keywordWords = weightedKeyword.keyword.toLowerCase().split(RegExp(r'\s+'));
        
        for (final kwWord in keywordWords) {
          // Skip very common words that could create false positives
          if (KeywordMatcher.isCommonWord(kwWord)) continue;
          
          if (contentWords.contains(kwWord)) {
            totalScore += weight * 0.8 * weightedKeyword.scoreMultiplier;
          }
        }
      }
    }
    
    // Specificity bonus: prefer more specific events over general ones
    totalScore += _getSpecificityBonus(event);
    
    // Exponential ongoing event bonus based on keyword occurrences
    if (isOngoing) {
      final allContent = '$title ${videoTitle ?? ''} $summary ${topic ?? ''}';
      final ongoingKeywordCount = _countOngoingKeywordOccurrences(allContent, event);
      totalScore += _calculateExponentialBonus(ongoingKeywordCount);
    }
    
    return totalScore;
  }
  
  /// Count occurrences of ongoing event keywords in content
  static int _countOngoingKeywordOccurrences(String content, IslamicEvent event) {
    int totalOccurrences = 0;
    for (final weightedKeyword in event.weightedKeywords) {
      totalOccurrences += KeywordMatcher.countOccurrences(content, weightedKeyword.keyword);
    }
    return totalOccurrences;
  }
  
  /// Calculate exponential bonus based on keyword occurrences
  /// Uses triangular number progression: 1→15, 2→45, 3→90, 4→150, 5→225
  static double _calculateExponentialBonus(int occurrences) {
    if (occurrences <= 0) return 0.0;
    // Triangular number formula: n(n+1)/2, multiplied by base bonus of 15
    return (occurrences * (occurrences + 1) / 2) * 15.0;
  }
  
  /// Get specificity bonus for an event
  static double _getSpecificityBonus(IslamicEvent event) {
    switch (event) {
      case IslamicEvent.LaylatAlQadr:
        return 2.0; // Most specific
      case IslamicEvent.DayOfArafah:
      case IslamicEvent.EidAlFitr:
      case IslamicEvent.EidAlAdha:
        return 1.5; // Specific events
      case IslamicEvent.IslamicNewYear:
        return 1.0; // Moderately specific
      case IslamicEvent.Ramadan:
        return 0.5; // General month
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
    
    // Get currently ongoing events for bonus scoring
    final ongoingEvents = IslamicEvent.currentIslamicEvent;
    
    IslamicEvent? bestEvent;
    double bestScore = 0.0;
    
    for (final event in IslamicEvent.values) {
      final score = ScoreCalculator.calculateEventScore(
        event: event,
        title: title,
        videoTitle: videoTitle,
        summary: summary,
        topic: topic,
        isOngoing: ongoingEvents.contains(event),
      );
      if (score > bestScore) {
        bestScore = score;
        bestEvent = event;
      }
    }
    
    // Only return event if it has a meaningful score
    return bestScore > 3.0 ? bestEvent : null;
  }
}