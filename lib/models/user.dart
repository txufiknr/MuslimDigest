import 'package:muslimdigest/mock/users.dart';

class User {
  final String userId;
  final String? name;
  final String? gender;
  final String? ageGroup;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    this.name,
    this.gender,
    this.ageGroup,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAnonymous => userId == anonymousUser.userId;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      gender: json['gender'],
      ageGroup: json['ageGroup'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'gender': gender,
      'ageGroup': ageGroup,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? gender,
    String? ageGroup,
  }) {
    return User(
      userId: userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
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
    required this.currentStreak,
    required this.longestStreak,
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