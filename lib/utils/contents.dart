import 'package:flutter/material.dart';

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