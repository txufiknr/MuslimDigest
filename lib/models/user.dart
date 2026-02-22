import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';

class User {
  final String userId;
  final String? name;
  final Gender? gender;
  final String? ageGroup;
  final int likedCount;
  final int savedCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    this.name,
    this.gender,
    this.ageGroup,
    this.likedCount = 0,
    this.savedCount = 0,
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      gender: json['gender'] == null ? null : Gender.fromString(json['gender']),
      ageGroup: json['ageGroup'],
      likedCount: json['likedCount'] ?? 0,
      savedCount: json['savedCount'] ?? 0,
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
      'likedCount': likedCount,
      'savedCount': savedCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    Gender? gender,
    String? ageGroup,
    int? likedCount,
    int? savedCount,
  }) {
    return User(
      userId: userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      likedCount: likedCount ?? this.likedCount,
      savedCount: savedCount ?? this.savedCount,
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
  likedCount: $likedCount,
  savedCount: $savedCount,
  createdAt: $createdAt,
  updatedAt: $updatedAt
)''';
  }
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
}

class UserPreferences {
  final String userId;
  final List<String> topics;
  final List<String> madhahib;
  final List<String> sources;
  final List<String> avoidedTopics;
  final List<String> avoidedSources;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserPreferences({
    required this.userId,
    this.topics = const [],
    this.madhahib = const [],
    this.sources = const [],
    this.avoidedTopics = const [],
    this.avoidedSources = const [],
    this.createdAt,
    this.updatedAt,
  });
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'],
      topics: List<String>.from(json['topics']),
      madhahib: List<String>.from(json['madhahib']),
      sources: List<String>.from(json['sources']),
      avoidedTopics: List<String>.from(json['avoidedTopics']),
      avoidedSources: List<String>.from(json['avoidedSources']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topics': topics,
      'madhahib': madhahib,
      'sources': sources,
      'avoidedTopics': avoidedTopics,
      'avoidedSources': avoidedSources,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? userId,
    List<String>? topics,
    List<String>? madhahib,
    List<String>? sources,
    List<String>? avoidedTopics,
    List<String>? avoidedSources,
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
}

class UserSettings {
  final String userId;
  final int textSize;
  final SwipeDirection swipeDirection;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    required this.userId,
    this.textSize = 18,
    this.swipeDirection = SwipeDirection.defaultDirection,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      textSize: json['textSize'] ?? 18,
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
}