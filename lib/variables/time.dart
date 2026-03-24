/// Returns the current date and time as a [DateTime] object.
DateTime get today => DateTime.now();

/// Returns the current date as a string in the format 'yyyy-mm-dd'.
String get todayString =>
    "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
