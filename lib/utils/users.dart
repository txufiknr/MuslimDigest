/// Extracts the first name from a full name string
/// 
/// Removes common honorifics and prefixes like "Mr.", "Mrs.", "Dr.", etc.
/// and returns the first word as the first name.
/// 
/// Parameters:
///   - [fullName]: The full name string to extract the first name from
/// 
/// Returns:
///   - `String` - The extracted first name, or empty string if input is invalid
/// 
/// Example:
/// ```dart
/// final firstName = extractFirstName('Mr. John Doe');
/// print(firstName); // Output: 'John'
/// ```
/// 
/// Note: This function is case-insensitive and handles multiple prefix formats.
/// It is designed to work with common English honorifics and religious titles.
String extractFirstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';
  
  final trimmedName = fullName.trim();
  
  // Remove common honorifics and prefixes
  final prefixes = ['mr.', 'mrs.', 'ms.', 'miss.', 'dr.', 'prof.', 'sir.', 'madam.', 'brother', 'sister'];
  var nameWithoutPrefix = trimmedName;
  
  for (final prefix in prefixes) {
    if (nameWithoutPrefix.toLowerCase().startsWith(prefix)) {
      nameWithoutPrefix = nameWithoutPrefix.substring(prefix.length).trim();
      break;
    }
  }
  
  // Split by spaces and get the first word
  final parts = nameWithoutPrefix.split(RegExp(r'\s+'));
  return parts.isNotEmpty ? parts.first : nameWithoutPrefix;
}