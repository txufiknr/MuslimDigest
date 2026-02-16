import 'package:flutter/material.dart';

const _kBulletChars = ['-', '*', '•'];

// Matches a bullet character that is preceded by start-of-string or whitespace,
// and followed by at least one whitespace character.
// This intentionally does NOT match mid-word hyphens like "non-religious".
final _kInlineBulletDetect = RegExp(r'(?:^|\s)[-*•]\s');

// Splits on any bullet character that is surrounded by optional whitespace.
final _kBulletSplit = RegExp(r'\s*[-*•]\s+');

/// Parsed result of a raw text string.
///
/// - [header] is the optional leading text before the first bullet (e.g. a
///   label ending in `:`, or an introductory sentence).
/// - [lines]  is the list of bullet-point strings, already stripped of their
///   leading bullet character.  Empty when the text contains no bullets.
@immutable
class _BulletParseResult {
  const _BulletParseResult({required this.header, required this.lines});

  final String? header;
  final List<String> lines;

  bool get hasBullets => lines.isNotEmpty;
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

/// Parses [rawText] into an optional header and a list of bullet lines.
///
/// Three strategies are tried in order:
///
/// 1. **Newline-separated** – when the text already contains line breaks,
///    split on `\n` and treat non-bullet lines before the first bullet as a
///    header; every bullet line is stripped of its marker.
///
/// 2. **Inline bullets** – when bullets appear inline (e.g. the text returned
///    by many AI APIs: `"- Item one. - Item two. - Item three."`), detect them
///    via [_kInlineBulletDetect] and split via [_kBulletSplit].
///    A non-empty first segment that precedes the first bullet is the header.
///    An empty first segment means the text started with a bullet (no header).
///
/// 3. **Single bullet line** – a single line that starts with a bullet marker.
///
/// When no bullets are found at all, [_BulletParseResult.lines] is empty.
_BulletParseResult _parseBulletText(String rawText) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return const _BulletParseResult(header: null, lines: []);

  // ── Strategy 1: newline-separated ─────────────────────────────────────────
  final newlineSegments = trimmed
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
      return _BulletParseResult(header: header, lines: lines);
    }
  }

  // ── Strategy 2: inline bullets ─────────────────────────────────────────────
  if (_kInlineBulletDetect.hasMatch(trimmed)) {
    final rawParts = trimmed.split(_kBulletSplit);

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
      return _BulletParseResult(header: header, lines: lines);
    }
  }

  // ── Strategy 3: single bullet line ─────────────────────────────────────────
  final stripped = _stripLeadingBullet(trimmed);
  if (stripped != null) {
    return _BulletParseResult(header: null, lines: [stripped]);
  }

  return const _BulletParseResult(header: null, lines: []);
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

/// Formats [rawText] into either a plain [Text] widget (when no bullet markers
/// are detected) or a [bulletedList] widget.
///
/// Handles all common bullet formats:
/// - Newline-separated: `"- Item\n- Item"`
/// - Inline with spaces: `"- Item. - Item. - Item."`
/// - Using `*` or `•` as markers in both modes above
/// - An optional header before the first bullet
///
/// Hyphenated words (e.g. `"non-religious"`, `"well-known"`) are never
/// misidentified as bullet separators.
Widget formatText(String rawText, {TextStyle? style}) {
  final result = _parseBulletText(rawText);

  if (!result.hasBullets) {
    return Text(rawText, style: style);
  }

  return bulletedList(
    result.lines,
    header: result.header,
    style: style,
  );
}