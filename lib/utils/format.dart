import 'package:flutter/material.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';

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
@immutable
class _ParseResult {
  const _ParseResult({
    this.header,
    this.lines = const [],
    this.question,
    this.answer,
    this.narrator,
    this.prophetStatement,
    this.quote,
    this.reference,
  });

  final String? header;
  final List<String> lines;
  final String? question;
  final String? answer;
  final String? narrator;
  final String? prophetStatement;
  final String? quote;
  final String? reference;

  bool get hasBullets => lines.isNotEmpty;
  bool get isQA => question != null && answer != null;
  bool get isHadith => narrator != null && quote != null;
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
_ParseResult _parseText(String rawText) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return const _ParseResult();

  // Preprocess text to replace smart quotes with standard quotes
  final normalizedText = trimmed
      .replaceAll('\u201C', '"')  // Left double quotation mark
      .replaceAll('\u201D', '"')  // Right double quotation mark
      .replaceAll('\u2018', "'")  // Left single quotation mark
      .replaceAll('\u2019', "'")  // Right single quotation mark
      .replaceAll('\u2026', '...') // Horizontal ellipsis
      .replaceAll('\u2013', '-')  // En dash
      .replaceAll('\u2014', '--'); // Em dash

  // ── Strategy 1: Hadith detection ────────────────────────────────────────────
  final hadithMatch = _kHadithPattern.firstMatch(normalizedText);
  if (hadithMatch != null) {
    return _ParseResult(
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
      question: qaMatch.group(1)?.trim(),
      answer: qaMatch.group(2)?.trim(),
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
      return _ParseResult(header: header, lines: lines);
    }
  }

  // ── Strategy 4: inline bullets ─────────────────────────────────────────────
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
      return _ParseResult(header: header, lines: lines);
    }
  }

  // ── Strategy 5: single bullet line ─────────────────────────────────────────
  final stripped = _stripLeadingBullet(normalizedText);
  if (stripped != null) {
    return _ParseResult(header: null, lines: [stripped]);
  }

  return const _ParseResult();
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
Widget qaPair(String question, String answer, {
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
          Text('Q: ', style: style?.copyWith(fontWeight: FontWeight.bold) ?? TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(question, style: style)),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A: ', style: style?.copyWith(fontWeight: FontWeight.bold) ?? TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(answer, style: style)),
        ],
      ),
    ],
  );
}

/// Formats [rawText] into either a plain [Text] widget, [qaPair] widget,
/// [bulletedList] widget, or [hadithNarration] widget based on content detection.
///
/// Handles:
/// - Hadith narrations: "Narrated Abu Huraira: The Prophet said, "[quote]" (reference)."
/// - Q&A format: "Q: What's the question? A: Here's the answer."
/// - Bullet lists with all common formats
/// - Plain text as fallback
///
/// Hyphenated words (e.g. "non-religious", "well-known") are never
/// misidentified as bullet separators.
Widget formatText(String rawText, {TextStyle? style}) {
  final result = _parseText(rawText);

  if (result.isHadith) {
    return hadithNarration(
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
      result.answer!,
      style: style,
    );
  }

  if (!result.hasBullets) {
    return Text(rawText, style: style);
  }

  return bulletedList(
    result.lines,
    header: result.header,
    style: style,
  );
}

/// Renders a hadith narration with narrator, prophet statement, quote, and reference.
///
/// The hadith is displayed as a column with three parts:
/// 1. Narrator and prophet statement (normal style)
/// 2. The quoted text (larger and italic style)
/// 3. The reference (normal style)
/// [spacing] controls the vertical gap between parts.
Widget hadithNarration(
  String narrator,
  String prophetStatement,
  String quote,
  String? reference, {
  TextStyle? style,
  double spacing = 16,
}) {
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
        color: Colors.teal[800],
      ) ?? TextStyle(
        fontSize: AppThemes.headlineSmallSize,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: Colors.teal[800],
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