import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/contents.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';

class FeedItem {
  final String id;
  final String title;
  final String summary;
  final String? summaryProvider;
  final String? summaryStatus;
  final String? sourceUrl;
  final String? canonicalUrl;
  final String? topic;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoTitle;
  final DateTime? publishedAt;
  final List<String> sources;
  final Cluster cluster;
  final List<String> badges;
  final Source source;
  final bool isBreaking;
  final bool isLiked;
  final bool isSaved;
  final int likeCount;
  final List<Cluster> alsoRead;
  final DateTime? createdAt;
  final FeedbackCategory? feedbackCategory; // For not interested reason
  final IslamicEventData? relatedEvent;

  FeedItem({
    required this.id,
    required this.title,
    required this.summary,
    this.summaryProvider,
    this.summaryStatus,
    this.sourceUrl,
    this.canonicalUrl,
    this.topic,
    this.imageUrl,
    this.videoUrl,
    this.videoTitle,
    this.publishedAt,
    this.sources = const [],
    this.createdAt,
    required this.cluster,
    this.badges = const [],
    required this.source,
    this.isBreaking = false,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount = 0,
    this.alsoRead = const [],
    this.feedbackCategory,
    this.relatedEvent,
  });

  bool get hasVideo => videoUrl != null;
  bool get hasYouTubeVideo => videoUrl?.contains('youtu') == true;
  bool get isNuanced => ['quran', 'hadith', 'fiqh'].contains(cluster.contentType);
  bool get isTrending => badges.contains('engagement:trending');
  bool get isHighlight => isTrending || isBreaking;
  bool get isEphemeral => badges.contains('content_tier:ephemeral') || cluster.contentType == 'news';

  String? get madhhab => badges.where((badge) => badge != 'madhhab:multiple').toList().firstWhereOrNull((badge) => badge.startsWith('maddhab:'));
  double get readTimeSeconds => cluster.readTime ?? estimateReadTime(summary);
  String get readTimeLabel => formatReadTime(readTimeSeconds);
  String? get hook => cluster.hook;
  String? get context => cluster.context;
  List<String> get keywords => cluster.keywords;
  List<String> get _badgeValuesToDisplay => badgeToDisplay.map((b) => b.split(':').last).toList();
  List<String> get keywordsToDisplay => keywords.where((k) => !_badgeValuesToDisplay.contains(k)).toList();

  // Display labels on feed card
  String get displayTitle => hasVideo ? (videoTitle ?? title) : title;
  String get sourceLabel => source.siteName ?? source.id;
  String? get sourceLink => canonicalUrl ?? sourceUrl;

  bool get isOngoing => relatedEvent?.isOngoing == true;
  String get vibeAnimationAsset => 'assets/lottie/vibes/${relatedEvent?.name.name}.json';

  List<String> get badgeToDisplay {
    final filteredBadges = badges.where((badge) => 
      // Hide all trust level badges
      !badge.startsWith('trust_level:') &&
      // Hide all summary status badges
      !badge.startsWith('summary_status:') &&
      // Hide all content risk badges except 'content_risk:high'
      (badge.startsWith('content_risk:') ? badge == 'content_risk:high' : true) &&
      // Hide all content tier badges except 'content_tier:evergreen'
      (badge.startsWith('content_tier:') ? badge == 'content_tier:evergreen' : true)
    ).toList();
    
    // Remove duplicate suffixes, keep first occurrence
    final seenSuffixes = <String>{};
    return filteredBadges.where((badge) {
      final suffix = badge.split(':').last;
      if (seenSuffixes.contains(suffix)) return false;
      seenSuffixes.add(suffix);
      return true;
    }).toList();
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      summaryProvider: json['summaryProvider'],
      summaryStatus: json['summaryStatus'],
      sourceUrl: json['sourceUrl'],
      canonicalUrl: json['canonicalUrl'],
      topic: json['topic'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      videoTitle: json['videoTitle'],
      publishedAt: json['publishedAt'] == null ? null : DateTime.parse(json['publishedAt']),
      createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt']),
      sources: List<String>.from(json['sources'] ?? []),
      cluster: Cluster.fromJson(json['cluster']),
      badges: List<String>.from(json['badges'] ?? []),
      alsoRead: List<Cluster>.from(List<Map<String, dynamic>>.from(json['alsoRead'] ?? []).map(Cluster.fromJson)),
      source: Source.fromJson(json['source']),
      likeCount: json['likeCount'] ?? 0,
      isBreaking: json['isBreaking'] ?? false,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      feedbackCategory: FeedbackCategory.fromString(json['feedbackCategory']),
      relatedEvent: json['relatedEvent'] == null ? null : IslamicEventData.fromJson(json['relatedEvent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'summaryProvider': summaryProvider,
      'summaryStatus': summaryStatus,
      'sourceUrl': sourceUrl,
      'canonicalUrl': canonicalUrl,
      'topic': topic,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'sources': sources,
      'cluster': cluster.toJson(),
      'badges': badges,
      'alsoRead': alsoRead.map((x) => x.toJson()).toList(),
      'source': source.toJson(),
      'isBreaking': isBreaking,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'likeCount': likeCount,
      'feedbackCategory': feedbackCategory?.name,
      'relatedEvent': relatedEvent?.toJson(),
    };
  }

  FeedItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? summaryProvider,
    String? summaryStatus,
    String? sourceUrl,
    String? canonicalUrl,
    String? topic,
    String? imageUrl,
    String? videoUrl,
    String? videoTitle,
    DateTime? publishedAt,
    List<String>? sources,
    Cluster? cluster,
    List<String>? badges,
    List<Cluster>? alsoRead,
    Source? source,
    bool? isBreaking,
    bool? isLiked,
    bool? isSaved,
    int? likeCount,
    FeedbackCategory? feedbackCategory,
    IslamicEventData? relatedEvent,
  }) {
    return FeedItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      summaryProvider: summaryProvider ?? this.summaryProvider,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      topic: topic ?? this.topic,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      publishedAt: publishedAt ?? this.publishedAt,
      sources: sources ?? this.sources,
      cluster: cluster ?? this.cluster,
      badges: badges ?? this.badges,
      alsoRead: alsoRead ?? this.alsoRead,
      source: source ?? this.source,
      isBreaking: isBreaking ?? this.isBreaking,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      likeCount: likeCount ?? this.likeCount,
      feedbackCategory: feedbackCategory ?? this.feedbackCategory,
      relatedEvent: relatedEvent ?? this.relatedEvent,
    );
  }

  @override
  String toString() {
    return '''
FeedItem(
  id: $id,
  title: $title,
  summary: $summary,
  summaryProvider: $summaryProvider,
  summaryStatus: $summaryStatus,
  sourceUrl: $sourceUrl,
  canonicalUrl: $canonicalUrl,
  topic: $topic,
  imageUrl: $imageUrl,
  videoUrl: $videoUrl,
  videoTitle: $videoTitle,
  publishedAt: $publishedAt,
  createdAt: $createdAt,
  sources: $sources,
  cluster: $cluster,
  badges: $badges,
  alsoRead: $alsoRead,
  source: $source,
  isBreaking: $isBreaking,
  isLiked: $isLiked,
  isSaved: $isSaved,
  likeCount: $likeCount,
  feedbackCategory: $feedbackCategory,
  relatedEvent: $relatedEvent,
)''';
  }
  
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is FeedItem &&
    runtimeType == other.runtimeType &&
    other.id == id &&
    other.title == title &&
    other.cluster == cluster &&
    other.isLiked == isLiked &&
    other.isSaved == isSaved &&
    other.likeCount == likeCount &&
    other.createdAt == createdAt &&
    other.feedbackCategory == feedbackCategory &&
    other.relatedEvent == relatedEvent
  );
}

class Cluster {
  final String id;
  final String? displayTitle;
  final String? topicPrimary;
  final int articleCount;
  final String? contentType;
  final double? readTime;
  final Map<String, int> topicDistribution;
  final double trendingScore;
  final String? trustLevel;
  final String? riskLevel;
  final String? heroImageUrl;
  final String? heroImageSource;
  final String? hook;
  final String? context;
  final List<String> keywords;
  final List<String> madhahib;
  final List<String> scholars;
  final DateTime? firstPublishedAt;
  final DateTime? lastPublishedAt;

  Cluster({
    required this.id,
    this.displayTitle,
    this.topicPrimary,
    this.articleCount = 1,
    this.contentType,
    this.readTime,
    this.topicDistribution = const {},
    this.trendingScore = 0.0,
    this.trustLevel,
    this.riskLevel,
    this.heroImageUrl,
    this.heroImageSource,
    this.hook,
    this.context,
    this.keywords = const [],
    this.madhahib = const [],
    this.scholars = const [],
    this.firstPublishedAt,
    this.lastPublishedAt,
  });

  Color get contentTypeColor => getContentTypeColor(contentType);

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'],
      displayTitle: json['displayTitle'],
      topicPrimary: json['topicPrimary'],
      articleCount: json['articleCount'] ?? 1,
      contentType: json['contentType'],
      readTime: json['readTime']?.toDouble(),
      topicDistribution: Map<String, int>.from(json['topicDistribution'] ?? {}),
      trendingScore: json['trendingScore']?.toDouble() ?? 0.0,
      trustLevel: json['trustLevel'],
      riskLevel: json['riskLevel'],
      heroImageUrl: json['heroImageUrl'],
      heroImageSource: json['heroImageSource'],
      hook: json['hook'],
      context: json['context'],
      keywords: List<String>.from(json['keywords'] ?? []),
      madhahib: List<String>.from(json['madhahib'] ?? []),
      scholars: List<String>.from(json['scholars'] ?? []),
      firstPublishedAt: json['firstPublishedAt'] == null ? null : DateTime.parse(json['firstPublishedAt']),
      lastPublishedAt: json['lastPublishedAt'] == null ? null : DateTime.parse(json['lastPublishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayTitle': displayTitle,
      'topicPrimary': topicPrimary,
      'articleCount': articleCount,
      'contentType': contentType,
      'readTime': readTime,
      'topicDistribution': topicDistribution,
      'trendingScore': trendingScore,
      'trustLevel': trustLevel,
      'riskLevel': riskLevel,
      'heroImageUrl': heroImageUrl,
      'heroImageSource': heroImageSource,
      'hook': hook,
      'context': context,
      'keywords': keywords,
      'madhahib': madhahib,
      'scholars': scholars,
      'firstPublishedAt': firstPublishedAt?.toIso8601String(),
      'lastPublishedAt': lastPublishedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '''
Cluster(
  id: $id,
  displayTitle: $displayTitle,
  topicPrimary: $topicPrimary,
  articleCount: $articleCount,
  contentType: $contentType,
  readTime: $readTime,
  topicDistribution: $topicDistribution,
  trendingScore: $trendingScore,
  trustLevel: $trustLevel,
  riskLevel: $riskLevel,
  heroImageUrl: $heroImageUrl,
  heroImageSource: $heroImageSource,
  hook: $hook,
  context: $context,
  keywords: $keywords,
  madhahib: $madhahib,
  scholars: $scholars,
  firstPublishedAt: $firstPublishedAt,
  lastPublishedAt: $lastPublishedAt
)''';
  }
  
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is Cluster &&
    runtimeType == other.runtimeType &&
    other.id == id &&
    other.displayTitle == displayTitle
  );
}

class Source {
  final String id;
  final String? name;
  final String? trustLevel;
  final String? siteName;
  final String? siteIcon;
  final String? ogImage;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final Gender? targetGender;

  Source({
    required this.id,
    this.name,
    this.trustLevel,
    this.siteName,
    this.siteIcon,
    this.ogImage,
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetGender,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      name: json['name'],
      trustLevel: json['trustLevel'],
      siteName: json['siteName'],
      siteIcon: json['siteIcon'],
      ogImage: json['ogImage'],
      targetAgeMin: json['targetAgeMin'],
      targetAgeMax: json['targetAgeMax'],
      targetGender: Gender.fromString(json['targetGender']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'trustLevel': trustLevel,
      'siteName': siteName,
      'siteIcon': siteIcon,
      'ogImage': ogImage,
      'targetAgeMin': targetAgeMin,
      'targetAgeMax': targetAgeMax,
      'targetGender': targetGender,
    };
  }

  @override
  String toString() {
    return '''
Source(
  id: $id,
  name: $name,
  trustLevel: $trustLevel,
  siteName: $siteName,
  siteIcon: $siteIcon,
  ogImage: $ogImage,
  targetAgeMin: $targetAgeMin,
  targetAgeMax: $targetAgeMax,
  targetGender: $targetGender
)''';
  }

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is Source &&
    runtimeType == other.runtimeType &&
    other.id == id &&
    other.name == name &&
    other.trustLevel == trustLevel &&
    other.siteName == siteName &&
    other.siteIcon == siteIcon &&
    other.ogImage == ogImage &&
    other.targetAgeMin == targetAgeMin &&
    other.targetAgeMax == targetAgeMax &&
    other.targetGender == targetGender
  );
}

class HijriEventDate {
  final int month; // 1-indexed Hijri month
  final int day;   // Day of month
  final int? duration; // Duration in days (for multi-day events)

  HijriEventDate({
    required this.month,
    required this.day,
    this.duration,
  });

  factory HijriEventDate.fromJson(Map<String, dynamic> json) {
    return HijriEventDate(
      month: json['month']?.toInt() ?? 1,
      day: json['day']?.toInt() ?? 1,
      duration: json['duration']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'day': day,
      'duration': duration,
    };
  }

  @override
  String toString() {
    return '''
HijriEventDate(
  month: $month,
  day: $day,
  duration: $duration
)''';
  }

  @override
  int get hashCode => Object.hash(month, day, duration);

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is HijriEventDate &&
    runtimeType == other.runtimeType &&
    other.month == month &&
    other.day == day &&
    other.duration == duration
  );
}

class IslamicEventData {
  final IslamicEvent name;
  final String title;
  final bool isOngoing;
  final String? startDate;
  final String? endDate;
  final HijriEventDate? hijriDate;
  final List<String>? libraryEventNames;

  IslamicEventData({
    required this.name,
    required this.title,
    required this.isOngoing,
    this.startDate,
    this.endDate,
    this.hijriDate,
    this.libraryEventNames,
  });

  factory IslamicEventData.fromJson(Map<String, dynamic> json) {
    return IslamicEventData(
      name: IslamicEvent.values.firstWhere(
        (e) => e.name == json['name'],
        orElse: () => throw ArgumentError('Invalid IslamicEvent: ${json['name']}'),
      ),
      title: json['title'] ?? '',
      isOngoing: json['isOngoing'] ?? false,
      startDate: json['startDate'],
      endDate: json['endDate'],
      hijriDate: json['hijriDate'] == null ? null : HijriEventDate.fromJson(json['hijriDate']),
      libraryEventNames: json['libraryEventNames'] == null 
        ? null 
        : List<String>.from(json['libraryEventNames']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.name,
      'title': title,
      'isOngoing': isOngoing,
      'startDate': startDate,
      'endDate': endDate,
      'hijriDate': hijriDate?.toJson(),
      'libraryEventNames': libraryEventNames,
    };
  }

  IslamicEventData copyWith({
    IslamicEvent? name,
    String? title,
    bool? isOngoing,
    String? startDate,
    String? endDate,
    HijriEventDate? hijriDate,
    List<String>? libraryEventNames,
  }) {
    return IslamicEventData(
      name: name ?? this.name,
      title: title ?? this.title,
      isOngoing: isOngoing ?? this.isOngoing,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hijriDate: hijriDate ?? this.hijriDate,
      libraryEventNames: libraryEventNames ?? this.libraryEventNames,
    );
  }

  @override
  String toString() {
    return '''
IslamicEventData(
  name: $name,
  title: $title,
  isOngoing: $isOngoing,
  startDate: $startDate,
  endDate: $endDate,
  hijriDate: $hijriDate,
  libraryEventNames: $libraryEventNames
)''';
  }

  @override
  int get hashCode => Object.hash(name, title, isOngoing, startDate, endDate, hijriDate, libraryEventNames);

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is IslamicEventData &&
    runtimeType == other.runtimeType &&
    other.name == name &&
    other.title == title &&
    other.isOngoing == isOngoing &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.hijriDate == hijriDate &&
    other.libraryEventNames == libraryEventNames
  );
}

class Vibe {
  final String title;
  final String? description;
  final MaterialColor? color;
 
  Vibe({
    required this.title,
    this.description,
    this.color,
  });
}