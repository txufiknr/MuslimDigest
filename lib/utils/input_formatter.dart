import 'package:flutter/services.dart';

/// A text input formatter that allows standard emojis while blocking complex/non-standard ones.
/// 
/// This formatter enables users to use common emojis in collection names (like ❤️, 🌟, 🌼)
/// while preventing problematic complex emojis that mobile keyboards may provide
/// (like 🤕, 🧑‍⚕️, 👨‍👩‍👧‍👦).
/// 
/// **Allowed characters:**
/// - Standard ASCII characters (letters, numbers, punctuation)
/// - Basic emojis from Unicode ranges: 0x1F600-0x1F64F, 0x1F300-0x1F5FF, 0x1F680-0x1F6FF
/// - Flags (0x1F1E0-0x1F1FF), dingbats (0x2700-0x27BF), geometric shapes (0x25A0-0x25FF)
/// - International characters and symbols from common language scripts
/// 
/// **Blocked characters:**
/// - Complex multi-codepoint emojis (Zwj sequences)
/// - Skin tone modifiers and other complex Unicode emoji variations
/// - Newer emoji sets that may cause display or compatibility issues
/// 
/// Used in collection name input fields to maintain consistency and prevent
/// problematic characters while still allowing user-friendly emoji usage.
class EmojiFilterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text;
    
    if (newText.isEmpty) return newValue;
    
    final StringBuffer filteredText = StringBuffer();
    
    for (int i = 0; i < newText.length; i++) {
      final String char = newText[i];
      final int codeUnit = char.codeUnitAt(0);
      
      // Allow standard ASCII characters, letters, numbers, punctuation
      if (codeUnit >= 0x20 && codeUnit <= 0x7E) {
        filteredText.write(char);
        continue;
      }
      
      // Allow standard emojis (basic emoji ranges)
      // Emoticons: 0x1F600-0x1F64F
      if (codeUnit >= 0x1F600 && codeUnit <= 0x1F64F) {
        filteredText.write(char);
        continue;
      }
      
      // Misc Symbols and Pictographs: 0x1F300-0x1F5FF
      if (codeUnit >= 0x1F300 && codeUnit <= 0x1F5FF) {
        filteredText.write(char);
        continue;
      }
      
      // Transport and Map: 0x1F680-0x1F6FF
      if (codeUnit >= 0x1F680 && codeUnit <= 0x1F6FF) {
        filteredText.write(char);
        continue;
      }
      
      // Flags: 0x1F1E0-0x1F1FF
      if (codeUnit >= 0x1F1E0 && codeUnit <= 0x1F1FF) {
        filteredText.write(char);
        continue;
      }
      
      // Dingbats: 0x2700-0x27BF
      if (codeUnit >= 0x2700 && codeUnit <= 0x27BF) {
        filteredText.write(char);
        continue;
      }
      
      // Geometric Shapes: 0x25A0-0x25FF
      if (codeUnit >= 0x25A0 && codeUnit <= 0x25FF) {
        filteredText.write(char);
        continue;
      }
      
      // Extended Unicode characters (including accented letters)
      if (codeUnit > 0x7F && codeUnit <= 0xFFFF) {
        // Check if it's a simple extended character (not complex emoji)
        // Allow most common international characters
        if (codeUnit <= 0x02AF || // IPA Extensions
            (codeUnit >= 0x0300 && codeUnit <= 0x036F) || // Combining Diacritical Marks
            (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF) || // Greek Extended
            (codeUnit >= 0x0400 && codeUnit <= 0x04FF) || // Cyrillic
            (codeUnit >= 0x0500 && codeUnit <= 0x052F) || // Cyrillic Supplement
            (codeUnit >= 0x0530 && codeUnit <= 0x058F) || // Armenian
            (codeUnit >= 0x0590 && codeUnit <= 0x05FF) || // Hebrew
            (codeUnit >= 0x0600 && codeUnit <= 0x06FF) || // Arabic
            (codeUnit >= 0x0700 && codeUnit <= 0x074F) || // Syriac
            (codeUnit >= 0x0750 && codeUnit <= 0x077F) || // Arabic Supplement
            (codeUnit >= 0x0780 && codeUnit <= 0x07BF) || // Thaana
            (codeUnit >= 0x0900 && codeUnit <= 0x097F) || // Devanagari
            (codeUnit >= 0x0980 && codeUnit <= 0x09FF) || // Bengali
            (codeUnit >= 0x0A00 && codeUnit <= 0x0A7F) || // Gurmukhi
            (codeUnit >= 0x0A80 && codeUnit <= 0x0AFF) || // Gujarati
            (codeUnit >= 0x0B00 && codeUnit <= 0x0B7F) || // Oriya
            (codeUnit >= 0x0B80 && codeUnit <= 0x0BFF) || // Tamil
            (codeUnit >= 0x0C00 && codeUnit <= 0x0C7F) || // Telugu
            (codeUnit >= 0x0C80 && codeUnit <= 0x0CFF) || // Kannada
            (codeUnit >= 0x0D00 && codeUnit <= 0x0D7F) || // Malayalam
            (codeUnit >= 0x0D80 && codeUnit <= 0x0DFF) || // Sinhala
            (codeUnit >= 0x0E00 && codeUnit <= 0x0E7F) || // Thai
            (codeUnit >= 0x0E80 && codeUnit <= 0x0EFF) || // Lao
            (codeUnit >= 0x0F00 && codeUnit <= 0x0FFF) || // Tibetan
            (codeUnit >= 0x1000 && codeUnit <= 0x109F) || // Myanmar
            (codeUnit >= 0x10A0 && codeUnit <= 0x10FF) || // Georgian
            (codeUnit >= 0x1100 && codeUnit <= 0x11FF) || // Hangul Jamo
            (codeUnit >= 0x1200 && codeUnit <= 0x137F) || // Ethiopic
            (codeUnit >= 0x13A0 && codeUnit <= 0x13FF) || // Cherokee
            (codeUnit >= 0x1400 && codeUnit <= 0x167F) || // Unified Canadian Aboriginal Syllabics
            (codeUnit >= 0x1680 && codeUnit <= 0x169F) || // Ogham
            (codeUnit >= 0x16A0 && codeUnit <= 0x16FF) || // Runic
            (codeUnit >= 0x1700 && codeUnit <= 0x171F) || // Tagalog
            (codeUnit >= 0x1720 && codeUnit <= 0x173F) || // Hanunoo
            (codeUnit >= 0x1740 && codeUnit <= 0x175F) || // Buhid
            (codeUnit >= 0x1760 && codeUnit <= 0x177F) || // Tagbanwa
            (codeUnit >= 0x1780 && codeUnit <= 0x17FF) || // Khmer
            (codeUnit >= 0x1800 && codeUnit <= 0x18AF) || // Mongolian
            (codeUnit >= 0x1900 && codeUnit <= 0x194F) || // Limbu
            (codeUnit >= 0x1950 && codeUnit <= 0x197F) || // Tai Le
            (codeUnit >= 0x1980 && codeUnit <= 0x19DF) || // New Tai Lue
            (codeUnit >= 0x19E0 && codeUnit <= 0x19FF) || // Khmer Symbols
            (codeUnit >= 0x1A00 && codeUnit <= 0x1A1F) || // Buginese
            (codeUnit >= 0x1B00 && codeUnit <= 0x1B7F) || // Balinese
            (codeUnit >= 0x1B80 && codeUnit <= 0x1BBF) || // Sundanese
            (codeUnit >= 0x1C00 && codeUnit <= 0x1C4F) || // Lepcha
            (codeUnit >= 0x1C50 && codeUnit <= 0x1C7F) || // Ol Chiki
            (codeUnit >= 0x1D00 && codeUnit <= 0x1D7F) || // Phonetic Extensions
            (codeUnit >= 0x1D80 && codeUnit <= 0x1DBF) || // Phonetic Extensions Supplement
            (codeUnit >= 0x1DC0 && codeUnit <= 0x1DFF) || // Combining Diacritical Marks Supplement
            (codeUnit >= 0x1E00 && codeUnit <= 0x1EFF) || // Latin Extended Additional
            (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF) || // Greek Extended
            (codeUnit >= 0x2000 && codeUnit <= 0x206F) || // General Punctuation
            (codeUnit >= 0x2070 && codeUnit <= 0x209F) || // Superscripts and Subscripts
            (codeUnit >= 0x20A0 && codeUnit <= 0x20CF) || // Currency Symbols
            (codeUnit >= 0x20D0 && codeUnit <= 0x20FF) || // Combining Diacritical Marks for Symbols
            (codeUnit >= 0x2100 && codeUnit <= 0x214F) || // Letterlike Symbols
            (codeUnit >= 0x2150 && codeUnit <= 0x218F) || // Number Forms
            (codeUnit >= 0x2190 && codeUnit <= 0x21FF) || // Arrows
            (codeUnit >= 0x2200 && codeUnit <= 0x22FF) || // Mathematical Operators
            (codeUnit >= 0x2300 && codeUnit <= 0x23FF) || // Miscellaneous Technical
            (codeUnit >= 0x2400 && codeUnit <= 0x243F) || // Control Pictures
            (codeUnit >= 0x2440 && codeUnit <= 0x245F) || // Optical Character Recognition
            (codeUnit >= 0x2460 && codeUnit <= 0x24FF) || // Enclosed Alphanumerics
            (codeUnit >= 0x2500 && codeUnit <= 0x257F) || // Box Drawing
            (codeUnit >= 0x2580 && codeUnit <= 0x259F) || // Block Elements
            (codeUnit >= 0x2600 && codeUnit <= 0x26FF) || // Miscellaneous Symbols
            (codeUnit >= 0x2700 && codeUnit <= 0x27BF) || // Dingbats
            (codeUnit >= 0x27C0 && codeUnit <= 0x27EF) || // Miscellaneous Mathematical Symbols-A
            (codeUnit >= 0x27F0 && codeUnit <= 0x27FF) || // Supplemental Arrows-A
            (codeUnit >= 0x2800 && codeUnit <= 0x28FF) || // Braille Patterns
            (codeUnit >= 0x2900 && codeUnit <= 0x297F) || // Supplemental Arrows-B
            (codeUnit >= 0x2980 && codeUnit <= 0x29FF) || // Miscellaneous Mathematical Symbols-B
            (codeUnit >= 0x2A00 && codeUnit <= 0x2AFF) || // Supplemental Mathematical Operators
            (codeUnit >= 0x2B00 && codeUnit <= 0x2BFF) || // Miscellaneous Symbols and Arrows
            (codeUnit >= 0x2C00 && codeUnit <= 0x2C5F) || // Glagolitic
            (codeUnit >= 0x2C60 && codeUnit <= 0x2C7F) || // Latin Extended-C
            (codeUnit >= 0x2C80 && codeUnit <= 0x2CFF) || // Coptic
            (codeUnit >= 0x2D00 && codeUnit <= 0x2D2F) || // Georgian Supplement
            (codeUnit >= 0x2D30 && codeUnit <= 0x2D7F) || // Tifinagh
            (codeUnit >= 0x2D80 && codeUnit <= 0x2DDF) || // Ethiopic Extended
            (codeUnit >= 0x2DE0 && codeUnit <= 0x2DFF) || // Cyrillic Extended-A
            (codeUnit >= 0x2E00 && codeUnit <= 0x2E7F) || // Supplemental Punctuation
            (codeUnit >= 0x2E80 && codeUnit <= 0x2EFF) || // CJK Radicals Supplement
            (codeUnit >= 0x2F00 && codeUnit <= 0x2FDF) || // Kangxi Radicals
            (codeUnit >= 0x2FF0 && codeUnit <= 0x2FFF) || // Ideographic Description Characters
            (codeUnit >= 0x3000 && codeUnit <= 0x303F) || // CJK Symbols and Punctuation
            (codeUnit >= 0x3040 && codeUnit <= 0x309F) || // Hiragana
            (codeUnit >= 0x30A0 && codeUnit <= 0x30FF) || // Katakana
            (codeUnit >= 0x3100 && codeUnit <= 0x312F) || // Bopomofo
            (codeUnit >= 0x3130 && codeUnit <= 0x318F) || // Hangul Compatibility Jamo
            (codeUnit >= 0x3190 && codeUnit <= 0x319F) || // Kanbun
            (codeUnit >= 0x31A0 && codeUnit <= 0x31BF) || // Bopomofo Extended
            (codeUnit >= 0x31C0 && codeUnit <= 0x31EF) || // CJK Strokes
            (codeUnit >= 0x31F0 && codeUnit <= 0x31FF) || // Katakana Phonetic Extensions
            (codeUnit >= 0x3200 && codeUnit <= 0x32FF) || // Enclosed CJK Letters and Months
            (codeUnit >= 0x3300 && codeUnit <= 0x33FF) || // CJK Compatibility
            (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) || // CJK Unified Ideographs Extension A
            (codeUnit >= 0x4DC0 && codeUnit <= 0x4DFF) || // Yijing Hexagram Symbols
            (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) || // CJK Unified Ideographs
            (codeUnit >= 0xA000 && codeUnit <= 0xA48F) || // Yi Syllables
            (codeUnit >= 0xA490 && codeUnit <= 0xA4CF) || // Yi Radicals
            (codeUnit >= 0xA4D0 && codeUnit <= 0xA4FF) || // Lisu
            (codeUnit >= 0xA500 && codeUnit <= 0xA63F) || // Vai
            (codeUnit >= 0xA640 && codeUnit <= 0xA69F) || // Cyrillic Extended-B
            (codeUnit >= 0xA6A0 && codeUnit <= 0xA6FF) || // Bamum
            (codeUnit >= 0xA700 && codeUnit <= 0xA71F) || // Modifier Tone Letters
            (codeUnit >= 0xA720 && codeUnit <= 0xA7FF) || // Latin Extended-D
            (codeUnit >= 0xA800 && codeUnit <= 0xA82F) || // Syloti Nagri
            (codeUnit >= 0xA830 && codeUnit <= 0xA83F) || // Common Indic Number Forms
            (codeUnit >= 0xA840 && codeUnit <= 0xA87F) || // Phags-pa
            (codeUnit >= 0xA880 && codeUnit <= 0xA8DF) || // Saurashtra
            (codeUnit >= 0xA8E0 && codeUnit <= 0xA8FF) || // Devanagari Extended
            (codeUnit >= 0xA900 && codeUnit <= 0xA92F) || // Kayah Li
            (codeUnit >= 0xA930 && codeUnit <= 0xA95F) || // Rejang
            (codeUnit >= 0xA960 && codeUnit <= 0xA97F) || // Hangul Jamo Extended-A
            (codeUnit >= 0xA980 && codeUnit <= 0xA9DF) || // Javanese
            (codeUnit >= 0xAA00 && codeUnit <= 0xAA5F) || // Cham
            (codeUnit >= 0xAA60 && codeUnit <= 0xAA7F) || // Myanmar Extended-A
            (codeUnit >= 0xAA80 && codeUnit <= 0xAADF) || // Tai Viet
            (codeUnit >= 0xAAE0 && codeUnit <= 0xAAFF) || // Meetei Mayek Extensions
            (codeUnit >= 0xAB00 && codeUnit <= 0xAB2F) || // Ethiopic Extended-A
            (codeUnit >= 0xABC0 && codeUnit <= 0xABFF) || // Meetei Mayek
            (codeUnit >= 0xAC00 && codeUnit <= 0xD7AF) || // Hangul Syllables
            (codeUnit >= 0xD7B0 && codeUnit <= 0xD7FF) || // Hangul Jamo Extended-B
            (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) || // CJK Compatibility Ideographs
            (codeUnit >= 0xFB00 && codeUnit <= 0xFB4F) || // Alphabetic Presentation Forms
            (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) || // Arabic Presentation Forms-A
            (codeUnit >= 0xFE00 && codeUnit <= 0xFE0F) || // Variation Selectors
            (codeUnit >= 0xFE10 && codeUnit <= 0xFE1F) || // Vertical Forms
            (codeUnit >= 0xFE20 && codeUnit <= 0xFE2F) || // Combining Half Marks
            (codeUnit >= 0xFE30 && codeUnit <= 0xFE4F) || // CJK Compatibility Forms
            (codeUnit >= 0xFE50 && codeUnit <= 0xFE6F) || // Small Form Variants
            (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF) || // Arabic Presentation Forms-B
            (codeUnit >= 0xFF00 && codeUnit <= 0xFFEF) || // Halfwidth and Fullwidth Forms
            (codeUnit >= 0xFFF0 && codeUnit <= 0xFFFF)) { // Specials
          filteredText.write(char);
          continue;
        }
      }
      
      // Skip complex emojis and other unwanted characters
      // This includes many of the newer, more complex emojis that mobile keyboards might provide
    }
    
    return TextEditingValue(
      text: filteredText.toString(),
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}