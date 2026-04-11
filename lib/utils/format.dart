import 'package:flutter/material.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

/// 🎯 Key Features Implemented:
///    - ParseMode Enum - Added ParseMode.primary vs ParseMode.nested for controlling recursion
///    - Enhanced _parseText - Added mode parameter with nested logic that skips Q&A, bullets, hadith in nested mode
///    - RawText Field - Added to _ParseResult for fallback text storage
///    - Unified Widget Builder - Created _buildWidgetFromResult() helper that handles all content types in one place
///    - Recursive Q&A Processing - Updated formatText to parse answers with nested quote detection
///    - Clean Architecture - Removed duplicate formatAnswerText function, eliminated code duplication

/// 🏗️ Architecture Benefits:
///    - Single Source of Truth - All pattern detection in _parseText() function
///    - Zero Duplication - No separate formatXText() functions needed
///    - Automatic Extensibility - New patterns work in nested contexts immediately
///    - Maintainable - Changes only in one place, easy to maintain

/// 📋 Future-Proof Scenarios Handled:
///    - Bullets in Q&A answers - Automatic with recursive parsing
///    - Quotes in bullet items - Automatic with recursive parsing
///    - Hadith in Q&A answers - Automatic with recursive parsing
///    - Any new content type - Just add detection to _parseText()

/// Parsing mode for controlling content detection behavior
enum ParseMode {
  /// Primary parsing mode - detects all content types (Q&A, bullets, quotes, etc.)
  primary,
  
  /// Nested parsing mode - only detects quote patterns, skips Q&A, bullets, hadith
  nested,
}

const _kBulletChars = ['-', '*', '•'];

// Matches a bullet character that is preceded by start-of-string or whitespace,
// and followed by at least one whitespace character.
// This intentionally does NOT match mid-word hyphens like "non-religious".
final _kInlineBulletDetect = RegExp(r'(?:^|\s)[-*•]\s');

// Splits on any bullet character that is surrounded by optional whitespace.
final _kBulletSplit = RegExp(r'\s*[-*•]\s+');

// Matches Q&A pattern: "Q: ... A: ..."
final _kQAPattern = RegExp(r'^\s*Q:\s*(.+?)\s*A:\s*(.+?)\s*$');

// Matches hadith narration pattern: "Narrated [narrator]: [prophet statement], "[quote]" ([reference])."
// Note: It's too strict, misses trailing period outside parens
// final _kHadithPattern = RegExp(r'^\s*Narrated\s+([^:]+):\s*([^,]+),\s*"([^"]+)"\s*\(([^)]+)\)\s*$');

// Matches hadith narration pattern: "Narrated [narrator]: [prophet statement], "[quote]" ([reference])."
final _kHadithPattern = RegExp(
  r'^\s*Narrated\s+([^:]+):\s*(.*?),\s*"([^"]*)"[.]?\s*(\([^)]+\)[.]?)?\s*$',
  dotAll: true,
);
// Matches comma quote pattern: ", "quoted text" (reference)"
final _kCommaQuotePattern = RegExp(
  r',\s*"([^"]+)"\s*\(([^)]+)\)',
);

// Matches general quote pattern: "prefix: "quoted text""
final _kGeneralQuotePattern = RegExp(
  r'(.+?):\s*"([^"]+)"',
);

// Matches words quote pattern: "prefix words: "quoted text""
final _kWordsQuotePattern = RegExp(
  r'(.*)words\s*:\s*"([^"]+)"',
  caseSensitive: false,
);

// Matches said quote pattern: "prefix said: "quoted text""
final _kSaidQuotePattern = RegExp(
  r'(.*)said\s*:\s*"([^"]+)"',
  caseSensitive: false,
);

// Matches stating and states quote patterns: "prefix stating/states, "quoted text""
final _kStatingQuotePattern = RegExp(
  r'(.*)stat(?:ing|es)\s*,\s*"([^"]+)"',
  caseSensitive: false,
);

// Matches bracket quote pattern: "prefix: "quoted text" [reference]"
final _kBracketQuotePattern = RegExp(
  r'(.+?):\s*"([^"]+)"\s*\[([^\]]+)\]',
);

// Matches asterisk pattern for italic text: "*text*"
final _kAsteriskPattern = RegExp(
  r'\*([^*]+)\*',
);

/// Parsed result of a raw text string.
///
/// - [header] is the optional leading text before the first bullet (e.g. a
///   label ending in `:`, or an introductory sentence).
/// - [lines]  is the list of bullet-point strings, already stripped of their
///   leading bullet character.  Empty when the text contains no bullets.
/// - [question] is the question part when Q&A format is detected.
/// - [answer] is the answer part when Q&A format is detected.
/// - [narrator] is the narrator part when hadith format is detected.
/// - [prophetStatement] is the prophet statement part when hadith format is detected.
/// - [quote] is the quoted text part when hadith format is detected.
/// - [reference] is the reference part when hadith format is detected.
/// - [commaQuote] is the quoted text part when comma quote pattern is detected.
/// - [commaQuoteText] is the full text before the comma quote pattern.
/// - [commaQuoteReference] is the reference part when comma quote pattern is detected.
/// - [generalQuote] is the quoted text part when general quote pattern is detected.
/// - [generalQuotePrefix] is the prefix text before the colon in general quote pattern.
/// - [wordsQuote] is the quoted text part when words quote pattern is detected.
/// - [wordsQuotePrefix] is the prefix word before the colon in words quote pattern.
/// - [saidQuote] is the quoted text part when said quote pattern is detected.
/// - [saidQuotePrefix] is the prefix words before the colon in said quote pattern.
/// - [statingQuote] is the quoted text part when stating/states quote pattern is detected.
/// - [statingQuotePrefix] is the prefix words before the comma in stating/states quote pattern.
/// - [bracketQuote] is the quoted text part when bracket quote pattern is detected.
/// - [bracketQuotePrefix] is the prefix text before the colon in bracket quote pattern.
/// - [bracketQuoteReference] is the reference text in square brackets for bracket quote pattern.
/// - [asteriskText] is the italic text part when asterisk pattern is detected.
/// - [trailing] is the text after the quote pattern.
/// - [rawText] is the original raw text for fallback.
@immutable
class _ParseResult {
  const _ParseResult({
    this.rawText,
    this.header,
    this.lines = const [],
    this.question,
    this.answer,
    this.narrator,
    this.prophetStatement,
    this.quote,
    this.reference,
    this.commaQuote,
    this.commaQuoteText,
    this.commaQuoteReference,
    this.generalQuote,
    this.generalQuotePrefix,
    this.wordsQuote,
    this.wordsQuotePrefix,
    this.saidQuote,
    this.saidQuotePrefix,
    this.statingQuote,
    this.statingQuotePrefix,
    this.bracketQuote,
    this.bracketQuotePrefix,
    this.bracketQuoteReference,
    this.asteriskText,
    this.trailing,
  });

  final String? rawText;
  final String? header;
  final List<String> lines;
  final String? question;
  final String? answer;
  final String? narrator;
  final String? prophetStatement;
  final String? quote;
  final String? reference;
  final String? commaQuote;
  final String? commaQuoteText;
  final String? commaQuoteReference;
  final String? generalQuote;
  final String? generalQuotePrefix;
  final String? wordsQuote;
  final String? wordsQuotePrefix;
  final String? saidQuote;
  final String? saidQuotePrefix;
  final String? statingQuote;
  final String? statingQuotePrefix;
  final String? bracketQuote;
  final String? bracketQuotePrefix;
  final String? bracketQuoteReference;
  final String? asteriskText;
  final String? trailing;

  bool get hasBullets => lines.isNotEmpty;
  bool get isQA => question != null && answer != null;
  bool get isHadith => narrator != null && quote != null;
  bool get hasCommaQuote => commaQuote != null;
  bool get hasGeneralQuote => generalQuote != null;
  bool get hasWordsQuote => wordsQuote != null;
  bool get hasSaidQuote => saidQuote != null;
  bool get hasStatingQuote => statingQuote != null;
  bool get hasBracketQuote => bracketQuote != null;
  bool get hasAsterisk => asteriskText != null;
}

/// Strips the leading bullet character from [line] and returns the trimmed
/// remainder, or `null` when [line] does not start with a bullet.
String? _stripLeadingBullet(String line) {
  for (final b in _kBulletChars) {
    // Require a space or tab after the bullet so we don't accidentally strip
    // mid-word hyphens that happen to appear at the very start of a segment.
    if (line.startsWith('$b ') || line.startsWith('$b\t')) {
      return line.substring(b.length).trim();
    }
    // For non-hyphen bullets (• and *) a trailing space is not strictly required
    // because these characters are unambiguously bullet markers.
    if (b != '-' && line.startsWith(b)) {
      return line.substring(b.length).trim();
    }
  }
  return null;
}

/// Parses [rawText] into Q&A format, bullet list, or plain text.
///
/// Three strategies are tried in order:
///
/// 1. **Hadith detection** – when the text matches "Narrated [narrator]: [prophet statement], "[quote]" ([reference])." pattern
///
/// 2. **Q&A detection** – when the text matches "Q: ... A: ..." pattern
///
/// 3. **Newline-separated** – when the text already contains line breaks,
///    split on `\n` and treat non-bullet lines before the first bullet as a
///    header; every bullet line is stripped of its marker.
///
/// 4. **Inline bullets** – when bullets appear inline (e.g. the text returned
///    by many AI APIs: `"- Item one. - Item two. - Item three."`), detect them
///    via [_kInlineBulletDetect] and split via [_kBulletSplit].
///    A non-empty first segment that precedes the first bullet is the header.
///    An empty first segment means the text started with a bullet (no header).
///
/// 5. **Single bullet line** – a single line that starts with a bullet marker.
/// When no bullets are found at all, [_ParseResult.lines] is empty.
_ParseResult _parseText(String rawText, {ParseMode mode = ParseMode.primary}) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return _ParseResult(rawText: rawText);

  // Preprocess text to replace smart quotes with standard quotes
  final normalizedText = trimmed
      .replaceAll('\u201C', '"')  // Left double quotation mark
      .replaceAll('\u201D', '"')  // Right double quotation mark
      .replaceAll('\u2018', "'")  // Left single quotation mark
      .replaceAll('\u2019', "'")  // Right single quotation mark
      .replaceAll('\u2026', '...'); // Horizontal ellipsis

  // In nested mode, skip primary content patterns to avoid recursion
  if (mode == ParseMode.primary) {
    // ── Strategy 1: Hadith detection ────────────────────────────────────────────
    final hadithMatch = _kHadithPattern.firstMatch(normalizedText);
    if (hadithMatch != null) {
      return _ParseResult(
        rawText: rawText,
        narrator: hadithMatch.group(1)?.trim(),
        prophetStatement: hadithMatch.group(2)?.trim(),
        quote: hadithMatch.group(3)?.trim(),
        reference: hadithMatch.group(4)?.trim(),
      );
    }

    // ── Strategy 2: Q&A detection ────────────────────────────────────────────
    final qaMatch = _kQAPattern.firstMatch(normalizedText);
    if (qaMatch != null) {
      return _ParseResult(
        rawText: rawText,
        question: qaMatch.group(1)?.trim(),
        answer: qaMatch.group(2)?.trim(),
      );
    }
  }

  // ── Strategy 2.5: Comma quote detection ─────────────────────────────────────
  final commaQuoteMatch = _kCommaQuotePattern.firstMatch(normalizedText);
  if (commaQuoteMatch != null) {
    final matchStart = commaQuoteMatch.start;
    final matchEnd = commaQuoteMatch.end;
    final beforeQuote = normalizedText.substring(0, matchStart).trim();
    final quoteText = commaQuoteMatch.group(1)?.trim();
    final referenceText = commaQuoteMatch.group(2)?.trim();
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    return _ParseResult(
      rawText: rawText,
      commaQuoteText: beforeQuote.isNotEmpty ? beforeQuote : null,
      commaQuote: quoteText,
      commaQuoteReference: referenceText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // ── Strategy 2.6: Words quote detection ─────────────────────────────
  final wordsQuoteMatch = _kWordsQuotePattern.firstMatch(normalizedText);
  if (wordsQuoteMatch != null) {
    final prefix = wordsQuoteMatch.group(1)?.trim();
    final quoteText = wordsQuoteMatch.group(2)?.trim();
    final matchEnd = wordsQuoteMatch.end;
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    return _ParseResult(
      rawText: rawText,
      wordsQuotePrefix: prefix?.isNotEmpty == true ? prefix : 'words',
      wordsQuote: quoteText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // ── Strategy 2.7: Said quote detection ─────────────────────────────
  final saidQuoteMatch = _kSaidQuotePattern.firstMatch(normalizedText);
  if (saidQuoteMatch != null) {
    final prefix = saidQuoteMatch.group(1)?.trim();
    final quoteText = saidQuoteMatch.group(2)?.trim();
    final matchEnd = saidQuoteMatch.end;
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    return _ParseResult(
      rawText: rawText,
      saidQuotePrefix: prefix?.isNotEmpty == true ? prefix : 'said',
      saidQuote: quoteText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // ── Strategy 2.8: General quote detection ─────────────────────────────
  final generalQuoteMatch = _kGeneralQuotePattern.firstMatch(normalizedText);
  if (generalQuoteMatch != null) {
    final prefix = generalQuoteMatch.group(1)?.trim();
    final quoteText = generalQuoteMatch.group(2)?.trim();
    final matchEnd = generalQuoteMatch.end;
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    return _ParseResult(
      rawText: rawText,
      generalQuotePrefix: prefix,
      generalQuote: quoteText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // ── Strategy 2.9: Stating/States quote detection ─────────────────────────────
  final statingQuoteMatch = _kStatingQuotePattern.firstMatch(normalizedText);
  if (statingQuoteMatch != null) {
    final prefix = statingQuoteMatch.group(1)?.trim();
    final quoteText = statingQuoteMatch.group(2)?.trim();
    final matchEnd = statingQuoteMatch.end;
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    // Determine which word was used (stating or states) and preserve it
    final matchedText = statingQuoteMatch.group(0)!;
    final usedWord = matchedText.contains('states') ? 'states' : 'stating';
    
    return _ParseResult(
      rawText: rawText,
      statingQuotePrefix: prefix?.isNotEmpty == true ? '$prefix $usedWord' : usedWord,
      statingQuote: quoteText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // Strategy 2.10: Bracket quote detection 
  final bracketQuoteMatch = _kBracketQuotePattern.firstMatch(normalizedText);
  if (bracketQuoteMatch != null) {
    final prefix = bracketQuoteMatch.group(1)?.trim();
    final quoteText = bracketQuoteMatch.group(2)?.trim();
    final referenceText = bracketQuoteMatch.group(3)?.trim();
    final matchEnd = bracketQuoteMatch.end;
    final afterQuote = normalizedText.substring(matchEnd).trim();
    
    return _ParseResult(
      rawText: rawText,
      bracketQuotePrefix: prefix,
      bracketQuote: quoteText,
      bracketQuoteReference: referenceText,
      trailing: afterQuote.isNotEmpty ? afterQuote : null,
    );
  }

  // Strategy 2.11: Asterisk pattern detection for italic text
  if (_kAsteriskPattern.hasMatch(normalizedText)) {
    // Use Text.rich to handle multiple asterisk occurrences
    return _ParseResult(
      rawText: rawText,
      asteriskText: normalizedText, // Store the full text for rich rendering
    );
  }

  // ── Strategy 3: newline-separated ─────────────────────────────────────────
  final newlineSegments = normalizedText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (newlineSegments.length > 1) {
    String? header;
    final lines = <String>[];
    for (final seg in newlineSegments) {
      final cleaned = _stripLeadingBullet(seg);
      if (cleaned != null) {
        lines.add(cleaned);
      } else if (lines.isEmpty) {
        // Lines before the first bullet form the header.
        header = header == null ? seg : '$header\n$seg';
      } else {
        // Non-bullet line after bullets have started → continuation content.
        lines.add(seg);
      }
    }
    if (lines.isNotEmpty) {
      return _ParseResult(rawText: rawText, header: header, lines: lines);
    }
  }

  // Strategy 4: inline bullets ─────────────────────────────────────────────
  if (_kInlineBulletDetect.hasMatch(normalizedText)) {
    final rawParts = normalizedText.split(_kBulletSplit);

    // When rawParts[0] is empty the original text started with a bullet marker,
    // so there is no header.  Otherwise rawParts[0] is text before the first
    // bullet and should be treated as the header.
    final startedWithBullet = rawParts.first.isEmpty;

    String? header;
    final lines = <String>[];

    for (var i = 0; i < rawParts.length; i++) {
      final part = rawParts[i].trim();
      if (part.isEmpty) continue;

      if (i == 0 && !startedWithBullet) {
        header = part;
      } else {
        lines.add(part);
      }
    }

    if (lines.isNotEmpty) {
      return _ParseResult(rawText: rawText, header: header, lines: lines);
    }
  }

  // ── Strategy 5: single bullet line ─────────────────────────────────────────
  final stripped = _stripLeadingBullet(normalizedText);
  if (stripped != null) {
    return _ParseResult(rawText: rawText, header: null, lines: [stripped]);
  }

  return _ParseResult(rawText: normalizedText);
}

/// Builds widget from _ParseResult using unified rendering logic
///
/// [result] is the parsed result to convert to widget
/// [style] is the optional text style to apply
Widget _buildWidgetFromResult(BuildContext context, _ParseResult result, {TextStyle? style}) {
  if (result.isHadith) {
    return hadithNarration(
      context,
      result.narrator!,
      result.prophetStatement!,
      result.quote!,
      result.reference,
      style: style,
    );
  }

  if (result.isQA) {
    return qaPair(
      result.question!,
      _buildWidgetFromResult(context, _parseText(result.answer!, mode: ParseMode.nested), style: style),
      style: style,
    );
  }

  if (result.hasCommaQuote) {
    return commaQuoteText(
      result.commaQuoteText,
      result.commaQuote!,
      result.commaQuoteReference,
      result.trailing,
      style: style,
    );
  }

  if (result.hasGeneralQuote) {
    return generalQuoteText(
      result.generalQuotePrefix!,
      result.generalQuote!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasWordsQuote) {
    return wordsQuoteText(
      result.wordsQuotePrefix!,
      result.wordsQuote!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasSaidQuote) {
    return saidQuoteText(
      result.saidQuotePrefix!,
      result.saidQuote!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasStatingQuote) {
    return statingQuoteText(
      result.statingQuotePrefix!,
      result.statingQuote!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasBracketQuote) {
    return bracketQuoteText(
      result.bracketQuotePrefix!,
      result.bracketQuote!,
      result.bracketQuoteReference!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasAsterisk) {
    return asteriskText(
      result.asteriskText!,
      afterText: result.trailing,
      style: style,
    );
  }

  if (result.hasBullets) {
    return bulletedList(
      result.lines,
      header: result.header,
      style: style,
    );
  }

  // Fallback to plain text if no patterns detected
  return Text(result.rawText ?? '', style: style);
}

/// Renders a bulleted list with an optional [header].
///
/// Each item in [lines] is displayed as a row with a bullet glyph on the left
/// and the item text expanding to fill the remaining width.
///
/// [spacing] controls the vertical gap between items (default 8 logical pixels).
Widget bulletedList(
  List<String> lines, {
  String? header,
  TextStyle? style,
  double spacing = 8,
}) {
  final children = <Widget>[
    if (header != null) Text(header, style: style),
    ...lines.map(
      (line) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(line, style: style)),
        ],
      ),
    ),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: spacing),
        children[i],
      ],
    ],
  );
}

/// Renders a Q&A pair with question and answer sections.
///
/// [question] and [answer] are displayed as separate text widgets
/// with "Q:" and "A:" prefixes respectively.
/// [spacing] controls the vertical gap between question and answer.
Widget qaPair(String question, Widget answer, {
  TextStyle? style,
  double spacing = 8,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q: ', style: style?.copyWith(fontWeight: FontWeight.w600) ?? TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(question, style: style)),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A: ', style: style?.copyWith(fontWeight: FontWeight.w600) ?? TextStyle(fontWeight: FontWeight.w600)),
          // Expanded(child: Text(answer, style: style)),
          Expanded(child: answer),
        ],
      ),
    ],
  );
}

/// Renders text with asterisk pattern for italic styling.
///
/// The text is displayed with all asterisk-wrapped portions styled as italic.
/// [fullText] is the complete text containing asterisk patterns.
/// [afterText] is unused (kept for compatibility).
Widget asteriskText(String fullText, {String? afterText, TextStyle? style}) {
  final italicStyle = style?.copyWith(
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  int lastIndex = 0;
  
  // Find all asterisk occurrences and build rich text
  for (final match in _kAsteriskPattern.allMatches(fullText)) {
    // Add text before the asterisk
    if (match.start > lastIndex) {
      textSpans.add(TextSpan(text: fullText.substring(lastIndex, match.start)));
    }
    
    // Add the italic text
    final italicText = match.group(1)!;
    textSpans.add(TextSpan(
      text: italicText,
      style: italicStyle,
    ));
    
    lastIndex = match.end;
  }
  
  // Add remaining text after the last asterisk
  if (lastIndex < fullText.length) {
    textSpans.add(TextSpan(text: fullText.substring(lastIndex)));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with comma quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [beforeText] is the text before the comma quote pattern.
/// [quoteText] is the quoted text to be styled.
/// [referenceText] is the reference text in parentheses.
/// [afterText] is the text after the comma quote pattern.
Widget commaQuoteText(String? beforeText, String quoteText, String? referenceText, String? afterText, {
  TextStyle? style,
}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add text before the quote if it exists
  if (beforeText != null && beforeText.isNotEmpty) {
    textSpans.add(TextSpan(text: beforeText));
    textSpans.add(TextSpan(text: ', '));
  }
  
  // Add the styled quote
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add the reference if it exists
  if (referenceText != null && referenceText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' ($referenceText)'));
  }
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: afterText));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with words quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [prefix] is the word before the colon.
/// [quoteText] is the quoted text to be styled.
/// [afterText] is the text after the quote pattern.
Widget wordsQuoteText(String prefix, String quoteText, {String? afterText, TextStyle? style}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add the prefix and styled quote
  textSpans.add(TextSpan(text: '$prefix: '));
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' $afterText'));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with said quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [prefix] is the words before the colon.
/// [quoteText] is the quoted text to be styled.
/// [afterText] is the text after the quote pattern.
Widget saidQuoteText(String prefix, String quoteText, {String? afterText, TextStyle? style}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add the prefix and styled quote
  textSpans.add(TextSpan(text: '$prefix: '));
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' $afterText'));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with general quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [prefix] is the text before the colon.
/// [quoteText] is the quoted text to be styled.
/// [afterText] is the text after the quote pattern.
Widget generalQuoteText(String prefix, String quoteText, {String? afterText, TextStyle? style}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add the prefix and styled quote
  textSpans.add(TextSpan(text: '$prefix: '));
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' $afterText'));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with stating quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [prefix] is the text before the comma.
/// [quoteText] is the quoted text to be styled.
/// [afterText] is the text after the quote pattern.
Widget statingQuoteText(String prefix, String quoteText, {String? afterText, TextStyle? style}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add the prefix and styled quote
  textSpans.add(TextSpan(text: '$prefix, '));
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' $afterText'));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Renders text with bracket quote pattern using Text.rich for bold and italic styling.
///
/// The text is displayed with the quoted portion styled as bold and italic.
/// [prefix] is the text before the colon.
/// [quoteText] is the quoted text to be styled.
/// [referenceText] is the reference text in square brackets.
/// [afterText] is the text after the quote pattern.
Widget bracketQuoteText(String prefix, String quoteText, String referenceText, {String? afterText, TextStyle? style}) {
  final quoteStyle = style?.copyWith(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  ) ?? TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  final textSpans = <TextSpan>[];
  
  // Add the prefix and styled quote
  textSpans.add(TextSpan(text: '$prefix: '));
  textSpans.add(TextSpan(
    text: '"$quoteText"',
    style: quoteStyle,
  ));
  
  // Add the reference in square brackets
  textSpans.add(TextSpan(text: ' [$referenceText]'));
  
  // Add text after the quote if it exists
  if (afterText != null && afterText.isNotEmpty) {
    textSpans.add(TextSpan(text: ' $afterText'));
  }

  return Text.rich(
    TextSpan(
      children: textSpans,
      style: style,
    ),
  );
}

/// Formats [rawText] into either a plain [Text] widget, [qaPair] widget,
/// [bulletedList] widget, or [hadithNarration] widget based on content detection.
///
/// Handles:
/// - Hadith narrations: "Narrated [narrator]: [prophet statement], "[quote]" ([reference])." pattern
/// - Q&A format: "Q: ... A: ..." pattern
/// - Bullet lists with all common formats
/// - Plain text as fallback
///
/// Hyphenated words (e.g. "non-religious", "well-known") are never
/// misidentified as bullet separators.
Widget formatText(BuildContext context, String rawText, {TextStyle? style}) {
  final result = _parseText(rawText);

  return _buildWidgetFromResult(context, result, style: style);
}

/// Renders a hadith narration with narrator, prophet statement, quote, and reference.
///
/// The hadith is displayed as a column with three parts:
/// 1. Narrator and prophet statement (normal style)
/// 2. The quoted text (larger and italic style)
/// 3. The reference (normal style)
/// [spacing] controls the vertical gap between parts.
Widget hadithNarration(
  BuildContext context,
  String narrator,
  String prophetStatement,
  String quote,
  String? reference, {
  TextStyle? style,
  double spacing = 16,
}) {
  final h = MyHelper(context);
  final hadithColor = h.useColor(Colors.teal, 800);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Narrated $narrator: $prophetStatement,',
        style: style,
      ),
      Text('“$quote”', style: style?.copyWith(
        fontSize: AppThemes.headlineSmallSize,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: hadithColor,
      ) ?? TextStyle(
        fontSize: AppThemes.headlineSmallSize,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: hadithColor,
      )),
      if (reference != null) Text(reference, style: style),
    ].addItemInBetween(SizedBox(height: spacing)),
  );
}

/// Formats a number with decimal separators (commas) for thousands.
///
/// [number] - The number to format
/// [decimalDigits] - Number of decimal places (default: 0)
///
/// Examples:
/// - formatNumber(1234) -> "1,234"
/// - formatNumber(1234567.89, decimalDigits: 2) -> "1,234,567.89"
/// - formatNumber(1000000) -> "1,000,000"
String formatNumber(num number, {int decimalDigits = 0}) {
  return number.toStringAsFixed(decimalDigits).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// Formats a DateTime with flexible display options for date, month, and year components.
///
/// [dateTime] - The DateTime to format
/// [showDate] - Whether to show the day (default: true)
/// [showMonth] - Whether to show the month (default: true)
/// [showYear] - Whether to show the year (default: true)
/// [monthFormat] - Format for month: 'short' (Jan), 'long' (January), or 'numeric' (1) (default: 'short')
/// [dateSeparator] - Separator between date components (default: ' ')
/// [includeTime] - Whether to include time (default: false)
/// [timeFormat] - Time format: '12h' (3:45 PM) or '24h' (15:45) (default: '12h')
///
/// Examples:
/// - formatDateTime(DateTime(2026, 3, 1)) -> "Mar 1, 2026"
/// - formatDateTime(DateTime(2026, 3, 1), showYear: false) -> "Mar 1"
/// - formatDateTime(DateTime(2026, 3, 1), showMonth: false) -> "1, 2026"
/// - formatDateTime(DateTime(2026, 3, 1), monthFormat: 'long') -> "March 1, 2026"
/// - formatDateTime(DateTime(2026, 3, 1), includeTime: true) -> "Mar 1, 2026 • 3:45 PM"
String formatDateTime(
  DateTime dateTime, {
  bool showDate = true,
  bool showMonth = true,
  bool showYear = true,
  String monthFormat = 'short',
  String dateSeparator = ' ',
  bool includeTime = false,
  String timeFormat = '12h',
}) {
  final List<String> parts = [];
  
  // Format month
  if (showMonth) {
    String monthStr;
    switch (monthFormat.toLowerCase()) {
      case 'long':
        monthStr = _getMonthNameLong(dateTime.month);
        break;
      case 'numeric':
        monthStr = dateTime.month.toString();
        break;
      case 'short':
      default:
        monthStr = _getMonthNameShort(dateTime.month);
        break;
    }
    parts.add(monthStr);
  }
  
  // Format date
  if (showDate) {
    parts.add(dateTime.day.toString());
  }
  
  // Format year
  if (showYear) {
    parts.add(dateTime.year.toString());
  }
  
  String dateStr = parts.join(dateSeparator);
  
  // Add time if requested
  if (includeTime) {
    final timeStr = _formatTime(dateTime, timeFormat);
    dateStr = '$dateStr • $timeStr';
  }
  
  return dateStr;
}

/// Returns short month name (Jan, Feb, etc.)
String _getMonthNameShort(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

/// Returns long month name (January, February, etc.)
String _getMonthNameLong(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

/// Formats time in 12h or 24h format
String _formatTime(DateTime dateTime, String format) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  
  switch (format.toLowerCase()) {
    case '24h':
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    case '12h':
    default:
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour < 12 ? 'AM' : 'PM';
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}