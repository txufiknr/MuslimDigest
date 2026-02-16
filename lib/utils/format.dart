const possibleBulletPoint = ['-', '*', '•'];

String formatText(String rawText) {
  // Check if there are bullet points in the middle of text (pattern: punctuation followed by bullet)
  final middleBulletPattern = RegExp(r'([.!?:])\s*([*•-])\s*');
  final match = middleBulletPattern.firstMatch(rawText);
  
  if (match != null) {
    // Handle bullet points in the middle of text
    final beforeBullets = rawText.substring(0, match.end);
    final afterBullets = rawText.substring(match.end);
    
    // Split the remaining text by bullet patterns
    final segments = afterBullets.split(RegExp(r'\s*[*•-]\s*'));
    final formattedLines = <String>[];
    
    // Add the text before bullets
    if (beforeBullets.trim().isNotEmpty) {
      formattedLines.add(beforeBullets.trim());
    }
    
    // Add each bullet point
    for (final segment in segments) {
      final trimmedSegment = segment.trim();
      if (trimmedSegment.isNotEmpty) {
        formattedLines.add('• $trimmedSegment');
      }
    }
    
    return formattedLines.join('\n');
  } else {
    // Handle bullet points at the start (original logic)
    final segments = rawText.split(' - ');
    final formattedLines = <String>[];
    
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
    
    return formattedLines.join('\n');
  }
}