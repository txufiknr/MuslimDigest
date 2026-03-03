import 'package:muslimdigest/config/settings.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';

class User {
  final String userId;
  final String? name;
  final Gender? gender;
  final String? ageGroup;
  final int totalLiked;
  final int totalSaved;
  final int totalReads;
  final int totalNotInterested;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    this.name,
    this.gender,
    this.ageGroup,
    this.totalLiked = 0,
    this.totalSaved = 0,
    this.totalReads = 0,
    this.totalNotInterested = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get firstName {
    final extractedFirstName = extractFirstName(name);
    if (extractedFirstName.isNotEmpty) return extractedFirstName;
    return switch (gender) {
      Gender.male => 'Brother',
      Gender.female => 'Sister',
      _ => 'Friend',
    };
  }

  // TODO: 5 emoji badge tier based on totalReads (0 - 100)
  String get totalReadsBadge {
    if (totalReads >= 0) return '🌱';
    return '🌱';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      gender: json['gender'] == null ? null : Gender.fromString(json['gender']),
      ageGroup: json['ageGroup'],
      totalLiked: json['totalLiked'] ?? 0,
      totalSaved: json['totalSaved'] ?? 0,
      totalReads: json['totalReads'] ?? 0,
      totalNotInterested: json['totalNotInterested'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'gender': gender?.name,
      'ageGroup': ageGroup,
      'totalLiked': totalLiked,
      'totalSaved': totalSaved,
      'totalReads': totalReads,
      'totalNotInterested': totalNotInterested,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    Gender? gender,
    String? ageGroup,
    int? totalLiked,
    int? totalSaved,
    int? totalReads,
    int? totalNotInterested,
  }) {
    return User(
      userId: userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      totalLiked: totalLiked ?? this.totalLiked,
      totalSaved: totalSaved ?? this.totalSaved,
      totalReads: totalReads ?? this.totalReads,
      totalNotInterested: totalNotInterested ?? this.totalNotInterested,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return '''
User(
  userId: $userId,
  name: $name,
  gender: $gender,
  ageGroup: $ageGroup,
  totalLiked: $totalLiked,
  totalSaved: $totalSaved,
  totalReads: $totalReads,
  totalNotInterested: $totalNotInterested,
  createdAt: $createdAt,
  updatedAt: $updatedAt
)''';
  }

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is User &&
    runtimeType == other.runtimeType &&
    other.userId == userId &&
    other.name == name &&
    other.gender == gender &&
    other.ageGroup == ageGroup &&
    other.totalLiked == totalLiked &&
    other.totalSaved == totalSaved &&
    other.totalReads == totalReads &&
    other.totalNotInterested == totalNotInterested
  );
}

class UserStreaks {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadAt;

  UserStreaks({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadAt,
  });

  factory UserStreaks.fromJson(Map<String, dynamic> json) {
    return UserStreaks(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }

  UserStreaks copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadAt,
  }) {
    return UserStreaks(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  String toString() {
    return '''
UserStreaks(
  currentStreak: $currentStreak,
  longestStreak: $longestStreak,
  lastReadAt: $lastReadAt
)''';
  }
  
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is UserStreaks &&
    runtimeType == other.runtimeType &&
    other.currentStreak == currentStreak &&
    other.longestStreak == longestStreak &&
    other.lastReadAt == lastReadAt
  );
}

class UserPreferences {
  final String userId;
  final Set<String> topics;
  final Set<String> madhahib;
  final Set<Source> sources;
  final Set<String> avoidedTopics;
  final Set<Source> avoidedSources;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserPreferences({
    required this.userId,
    this.topics = const {},
    this.madhahib = const {},
    this.sources = const {},
    this.avoidedTopics = const {},
    this.avoidedSources = const {},
    this.createdAt,
    this.updatedAt,
  });
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'],
      topics: Set<String>.from(json['topics'] ?? []),
      madhahib: Set<String>.from(json['madhahib'] ?? []),
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []).map(Source.fromJson).toSet(),
      avoidedTopics: Set<String>.from(json['avoidedTopics'] ?? []),
      avoidedSources: List<Map<String, dynamic>>.from(json['avoidedSources'] ?? []).map(Source.fromJson).toSet(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topics': topics.toList(),
      'madhahib': madhahib.toList(),
      'sources': sources.map((s) => s.toJson()).toList(),
      'avoidedTopics': avoidedTopics.toList(),
      'avoidedSources': avoidedSources.map((s) => s.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? userId,
    Set<String>? topics,
    Set<String>? madhahib,
    Set<Source>? sources,
    Set<String>? avoidedTopics,
    Set<Source>? avoidedSources,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      topics: topics ?? this.topics,
      madhahib: madhahib ?? this.madhahib,
      sources: sources ?? this.sources,
      avoidedTopics: avoidedTopics ?? this.avoidedTopics,
      avoidedSources: avoidedSources ?? this.avoidedSources,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '''
UserPreferences(
  userId: $userId,
  topics: $topics,
  madhahib: $madhahib,
  sources: $sources,
  avoidedTopics: $avoidedTopics,
  avoidedSources: $avoidedSources,
  createdAt: $createdAt,
  updatedAt: $updatedAt
)''';
  }

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is UserPreferences &&
    runtimeType == other.runtimeType &&
    other.userId == userId &&
    other.topics == topics &&
    other.madhahib == madhahib &&
    other.sources == sources &&
    other.avoidedTopics == avoidedTopics &&
    other.avoidedSources == avoidedSources
  );
}

class UserSettings {
  final String userId;
  final int textSize;
  final SwipeDirection swipeDirection;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    required this.userId,
    this.textSize = DEFAULT_TEXT_SIZE,
    this.swipeDirection = SwipeDirection.defaultDirection,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      textSize: json['textSize'] ?? DEFAULT_TEXT_SIZE,
      swipeDirection: json['swipeDirection'] == null ? SwipeDirection.defaultDirection : SwipeDirection.fromString(json['swipeDirection']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'textSize': textSize,
      'swipeDirection': swipeDirection.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? userId,
    int? textSize,
    SwipeDirection? swipeDirection,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      textSize: textSize ?? this.textSize,
      swipeDirection: swipeDirection ?? this.swipeDirection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '''
UserSettings(
  userId: $userId,
  textSize: $textSize,
  swipeDirection: $swipeDirection,
  createdAt: $createdAt,
  updatedAt: $updatedAt
)''';
  }

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is UserSettings &&
    runtimeType == other.runtimeType &&
    other.userId == userId &&
    other.textSize == textSize &&
    other.swipeDirection == swipeDirection
  );
}