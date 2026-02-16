import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';

const possibleBulletPoint = ['-', '*', '•'];

Widget bulletedList(List<String> lines, {String? header, TextStyle? style}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (header != null) Text(header, style: style),
      ...lines.map((line) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Text(line, style: style).expand(),
        ],
      )),
    ],
  );
}

Widget formatText(String rawText, {TextStyle? style}) {
  // Check if there are bullet points in the middle of text (pattern: punctuation followed by bullet)
  final middleBulletPattern = RegExp(r'([.!?:])\s*([*•-])\s*');
  final match = middleBulletPattern.firstMatch(rawText);
  final formattedLines = <String>[];
  String? header;
  
  if (match != null) {
    // Handle bullet points in the middle of text
    final beforeBullets = rawText.substring(0, match.end);
    final afterBullets = rawText.substring(match.end);
    
    // Split the remaining text by bullet patterns
    final segments = afterBullets.split(RegExp(r'\s*[*•-]\s*'));
    
    // Add the text before bullets
    if (beforeBullets.trim().isNotEmpty) {
      header = beforeBullets.trim();
    }
    
    // Add each bullet point
    for (final segment in segments) {
      final trimmedSegment = segment.trim();
      if (trimmedSegment.isNotEmpty) {
        formattedLines.add(trimmedSegment);
      }
    }
  } else {
    // Handle bullet points at the start (original logic)
    final segments = rawText.split(' - ');
    if (segments.length == 1) {
      return Text(rawText, style: style);
    }

    for (final segment in segments) {
      final trimmedSegment = segment.trim();
      if (trimmedSegment.isNotEmpty) {
        // Check if segment starts with any bullet point and remove it
        String cleanText = trimmedSegment;
        for (final bullet in possibleBulletPoint) {
          if (cleanText.startsWith(bullet)) {
            cleanText = cleanText.substring(bullet.length).trim();
            break;
          }
        }
        formattedLines.add('• $cleanText');
      }
    }
  }

  return bulletedList(formattedLines, header: header, style: style);
}