const possibleBulletPoint = ['-', '*', '•'];

String formatText(String rawText) {
  final lines = rawText.split('\n');
  final formattedLines = <String>[];
  
  for (final line in lines) {
    final trimmedLine = line.trim();
    bool isBulletPoint = false;
    
    // Check if line starts with any possible bullet point
    for (final bullet in possibleBulletPoint) {
      if (trimmedLine.startsWith(bullet)) {
        isBulletPoint = true;
        // Remove the bullet point and extra whitespace
        final bulletText = trimmedLine.substring(bullet.length).trim();
        formattedLines.add('• $bulletText');
        break;
      }
    }
    
    if (!isBulletPoint) {
      formattedLines.add(line);
    }
  }
  
  return formattedLines.join('\n');
}