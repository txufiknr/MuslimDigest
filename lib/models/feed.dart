import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart';

import '../utils/extensions.dart';

class FeedItem {
  final String id;
  final String title;
  final String summary;
  final String? summaryProvider;
  final String? summaryStatus;
  final String? sourceUrl;
  final String? canonicalUrl;
  final String? hook;
  final String? topic;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoTitle;
  final String? riskLevel;
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

  FeedItem({
    required this.id,
    required this.title,
    required this.summary,
    this.summaryProvider,
    this.summaryStatus,
    this.sourceUrl,
    this.canonicalUrl,
    this.hook,
    this.topic,
    this.imageUrl,
    this.videoUrl,
    this.videoTitle,
    this.riskLevel,
    this.publishedAt,
    this.createdAt,
    this.sources = const [],
    required this.cluster,
    this.badges = const [],
    required this.source,
    this.isBreaking = false,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount = 0,
    this.alsoRead = const [],
    this.feedbackCategory,
  });

  bool get hasVideo => videoUrl != null;
  bool get hasYouTubeVideo => videoUrl?.contains('youtu') == true;
  bool get isNuanced => ['quran', 'hadith', 'fiqh'].contains(cluster.contentType);

  // Display labels on feed card
  String get displayTitle => hasVideo ? (videoTitle ?? title) : title;
  String get sourceLabel => source.siteName ?? source.id;
  String? get sourceLink => canonicalUrl ?? sourceUrl;

  IslamicEvent? get relevantEvent {
    return IslamicEvent.values.firstWhereOrNull((e) {
      return [title, videoTitle, summary, topic].containsAnyIgnoreCase(e.keywords);
    });
  }
  bool get isOngoing => relevantEvent?.isOngoing == true;
  String get vibeAnimationAsset => 'assets/lottie/vibes/${relevantEvent?.name}.json';

  List<String> get badgeToDisplay => badges.where((badge) => 
    !badge.startsWith('trust_level:') &&
    !badge.startsWith('summary_status:') &&
    (badge != 'content_risk:high' ? !badge.startsWith('content_risk:') : true)
  ).toList();

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      summaryProvider: json['summaryProvider'],
      summaryStatus: json['summaryStatus'],
      sourceUrl: json['sourceUrl'],
      canonicalUrl: json['canonicalUrl'],
      hook: json['hook'],
      topic: json['topic'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      videoTitle: json['videoTitle'],
      riskLevel: json['riskLevel'],
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
      'hook': hook,
      'topic': topic,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'riskLevel': riskLevel,
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
      'feedbackCategory': feedbackCategory,
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
    String? hook,
    String? topic,
    String? imageUrl,
    String? videoUrl,
    String? videoTitle,
    String? riskLevel,
    DateTime? publishedAt,
    DateTime? createdAt,
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
  }) {
    return FeedItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      summaryProvider: summaryProvider ?? this.summaryProvider,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      hook: hook ?? this.hook,
      topic: topic ?? this.topic,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      riskLevel: riskLevel ?? this.riskLevel,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
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
  hook: $hook,
  topic: $topic,
  imageUrl: $imageUrl,
  videoUrl: $videoUrl,
  riskLevel: $riskLevel,
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
    other.isBreaking == isBreaking &&
    other.isLiked == isLiked &&
    other.isSaved == isSaved &&
    other.likeCount == likeCount &&
    other.createdAt == createdAt
  );
}

class Cluster {
  final String id;
  final String? displayTitle;
  final int articleCount;
  final String? contentType;
  final Map<String, int> topicDistribution;
  final double trendingScore;
  final String? trustLevel;
  final String? heroImageUrl;
  final List<String> madhahib;
  final List<String> scholars;
  final DateTime? firstPublishedAt;
  final DateTime? lastPublishedAt;

  Cluster({
    required this.id,
    this.displayTitle,
    this.articleCount = 1,
    this.contentType,
    this.topicDistribution = const {},
    this.trendingScore = 0.0,
    this.trustLevel,
    this.heroImageUrl,
    this.madhahib = const [],
    this.scholars = const [],
    this.firstPublishedAt,
    this.lastPublishedAt,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'],
      articleCount: json['articleCount'] ?? 1,
      contentType: json['contentType'],
      topicDistribution: Map<String, int>.from(json['topicDistribution'] ?? {}),
      trendingScore: json['trendingScore']?.toDouble() ?? 0.0,
      trustLevel: json['trustLevel'],
      heroImageUrl: json['heroImageUrl'],
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
      'articleCount': articleCount,
      'contentType': contentType,
      'topicDistribution': topicDistribution,
      'trendingScore': trendingScore,
      'trustLevel': trustLevel,
      'heroImageUrl': heroImageUrl,
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
  articleCount: $articleCount,
  contentType: $contentType,
  topicDistribution: $topicDistribution,
  trendingScore: $trendingScore,
  trustLevel: $trustLevel,
  heroImageUrl: $heroImageUrl,
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

  Source({
    required this.id,
    this.name,
    this.trustLevel,
    this.siteName,
    this.siteIcon,
    this.ogImage,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      name: json['name'],
      trustLevel: json['trustLevel'],
      siteName: json['siteName'],
      siteIcon: json['siteIcon'],
      ogImage: json['ogImage'],
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
  ogImage: $ogImage
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
    other.ogImage == ogImage
  );
}
