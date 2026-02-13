class FeedItem {
  final String id;
  final String title;
  final String summary;
  final String summaryProvider;
  final String summaryStatus;
  final String sourceUrl;
  final String topic;
  final String? image;
  final String? video;
  final String riskLevel;
  final DateTime publishedAt;
  final List<String> sources;
  final Cluster cluster;
  final List<String> badges;
  final Source source;
  final bool isBreaking;

  FeedItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.summaryProvider,
    required this.summaryStatus,
    required this.sourceUrl,
    required this.topic,
    this.image,
    this.video,
    required this.riskLevel,
    required this.publishedAt,
    required this.sources,
    required this.cluster,
    required this.badges,
    required this.source,
    required this.isBreaking,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      summaryProvider: json['summaryProvider'],
      summaryStatus: json['summaryStatus'],
      sourceUrl: json['sourceUrl'],
      topic: json['topic'],
      image: json['image'],
      video: json['video'],
      riskLevel: json['riskLevel'],
      publishedAt: DateTime.parse(json['publishedAt']),
      sources: List<String>.from(json['sources']),
      cluster: Cluster.fromJson(json['cluster']),
      badges: List<String>.from(json['badges']),
      source: Source.fromJson(json['source']),
      isBreaking: json['isBreaking'] ?? false,
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
      'topic': topic,
      'image': image,
      'video': video,
      'riskLevel': riskLevel,
      'publishedAt': publishedAt.toIso8601String(),
      'sources': sources,
      'cluster': cluster.toJson(),
      'badges': badges,
      'source': source.toJson(),
      'isBreaking': isBreaking,
    };
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
  topic: $topic,
  image: $image,
  video: $video,
  riskLevel: $riskLevel,
  publishedAt: $publishedAt,
  sources: $sources,
  cluster: $cluster,
  badges: $badges,
  source: $source,
  isBreaking: $isBreaking
)''';
  }
}

class Cluster {
  final String id;
  final int articleCount;
  final Map<String, int> topicDistribution;
  final double trendingScore;
  final String trustLevel;
  final String? heroImageUrl;
  final List<String> madhahib;
  final List<String> scholars;
  final DateTime firstPublishedAt;
  final DateTime lastPublishedAt;

  Cluster({
    required this.id,
    required this.articleCount,
    required this.topicDistribution,
    required this.trendingScore,
    required this.trustLevel,
    this.heroImageUrl,
    this.madhahib = const [],
    this.scholars = const [],
    required this.firstPublishedAt,
    required this.lastPublishedAt,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'],
      articleCount: json['articleCount'],
      topicDistribution: Map<String, int>.from(json['topicDistribution']),
      trendingScore: json['trendingScore']?.toDouble() ?? 0.0,
      trustLevel: json['trustLevel'],
      heroImageUrl: json['heroImageUrl'],
      madhahib: List<String>.from(json['madhahib'] ?? []),
      scholars: List<String>.from(json['scholars'] ?? []),
      firstPublishedAt: DateTime.parse(json['firstPublishedAt']),
      lastPublishedAt: DateTime.parse(json['lastPublishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleCount': articleCount,
      'topicDistribution': topicDistribution,
      'trendingScore': trendingScore,
      'trustLevel': trustLevel,
      'heroImageUrl': heroImageUrl,
      'madhahib': madhahib,
      'scholars': scholars,
      'firstPublishedAt': firstPublishedAt.toIso8601String(),
      'lastPublishedAt': lastPublishedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '''
Cluster(
  id: $id,
  articleCount: $articleCount,
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
}

class Source {
  final String id;
  final String name;
  final String trustLevel;
  final String siteName;
  final String? siteIcon;
  final String? ogImage;

  Source({
    required this.id,
    required this.name,
    required this.trustLevel,
    required this.siteName,
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
}
