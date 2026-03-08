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
    case 'hadith': return Colors.amber;
    case 'knowledge': return Colors.blue;
    case 'news': return Colors.cyan;
    case 'qna': return Colors.orange;
    case 'quran': return Colors.brown;
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