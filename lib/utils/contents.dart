import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';

String getContentTypeLabel(String? contentType) {
  contentType ??= 'article';
  switch (contentType) {
    case 'qna': return 'Q&A';
    default: return contentType.unslugTitleCase();
  }
}

MaterialColor getContentTypeColor(String? contentType) {
  switch (contentType ?? 'article') {
    case 'article': return Colors.green;
    case 'education': return Colors.indigo;
    case 'hadith': return Colors.teal;
    case 'knowledge': return Colors.blue;
    case 'news': return Colors.cyan;
    case 'qna': return Colors.orange;
    case 'quran': return Colors.teal;
    case 'virtue': return Colors.deepOrange;
    default: return Colors.teal;
  }
}

String getTopicLabel(String topic) {
  if (topic == 'quran') return 'Qur’an';
  if (topic == 'dua') return 'Duʿa';
  if (topic == 'news' || topic == 'muslimworld') return 'Muslim world';
  return topic.toCapitalized();
}

MaterialColor getTopicColor(String? topic) {
    // Topic-specific colors
  switch (topic) {
    case 'aqeedah': return Colors.deepOrange;
    case 'dua': return Colors.lightGreen;
    case 'eschatology': return Colors.blueGrey;
    case 'ethic': return Colors.blue;
    case 'family': return Colors.purple;
    case 'fasting': return Colors.lime;
    case 'fiqh': return Colors.indigo;
    case 'hadith': return Colors.teal;
    case 'history': return Colors.brown;
    case 'news': case 'muslimworld': return Colors.cyan;
    case 'opinion': return Colors.red;
    case 'quran': return Colors.teal;
    case 'seerah': return Colors.brown;
    case 'social': return Colors.green;
    case 'worship': return Colors.deepPurple;
    default: return Colors.teal;
  }
}