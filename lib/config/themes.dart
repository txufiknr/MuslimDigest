import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppThemes {
  // Global text height multiplier
  static const double textHeightMultiplier = 1.3;
  
  // Text sizes
  static const double displayLargeSize = 36;
  static const double displayMediumSize = 28;
  static const double headlineLargeSize = 24;
  static const double headlineMediumSize = 20;
  static const double titleLargeSize = 22;
  static const double titleMediumSize = 21;
  static const double bodyLargeSize = 22;
  static const double bodyMediumSize = 17.5;
  static const double bodySmallSize = 14;
  static const double labelLargeSize = 22;
  static const double labelSmallSize = 18;
  static const double buttonLargeSize = 20;
  static const double buttonSmallSize = 16;

  static const double buttonHeight = 50.0;
  static const double contentPadding = 22.0;
  
  // Color Schemes
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceLight,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryLight,
    onError: Colors.white,
  );

  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceDark,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryDark,
    onError: Colors.white,
  );

  // AppBar Themes
  // static AppBarTheme get appBarThemeLight => AppBarTheme(
  //   backgroundColor: AppColors.primary,
  //   foregroundColor: Colors.white,
  //   elevation: 2,
  //   centerTitle: true,
  //   titleTextStyle: GoogleFonts.sourceSans3(
  //     color: Colors.white,
  //     fontSize: 20,
  //     fontWeight: FontWeight.w600,
  //   ),
  // );

  // static AppBarTheme get appBarThemeDark => AppBarTheme(
  //   backgroundColor: AppColors.primaryDark,
  //   foregroundColor: Colors.white,
  //   elevation: 2,
  //   centerTitle: true,
  //   titleTextStyle: GoogleFonts.sourceSans3(
  //     color: Colors.white,
  //     fontSize: 20,
  //     fontWeight: FontWeight.w600,
  //   ),
  // );

  // Button Styles
  static ButtonStyle get elevatedButtonStyleLight => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    textStyle: GoogleFonts.sourceSans3(
      fontWeight: FontWeight.w500,
      fontSize: buttonLargeSize,
    ),
  );

  static ButtonStyle get elevatedButtonStyleDark => elevatedButtonStyleLight.copyWith(
    backgroundColor: WidgetStateProperty.all(Colors.white),
    foregroundColor: WidgetStateProperty.all(AppColors.primary),
  );

  static ButtonStyle get outlinedButtonStyleLight => OutlinedButton.styleFrom(
    side: const BorderSide(color: AppColors.primary),
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    textStyle: GoogleFonts.sourceSans3(
      fontWeight: FontWeight.w500,
      fontSize: buttonLargeSize,
    ),
  );

  static ButtonStyle get outlinedButtonStyleDark => outlinedButtonStyleLight.copyWith(
    side: WidgetStateProperty.all(const BorderSide(color: Colors.white)),
    foregroundColor: WidgetStateProperty.all(Colors.white),
  );

  // Button Themes
  static ElevatedButtonThemeData get elevatedButtonThemeLight => ElevatedButtonThemeData(
    style: elevatedButtonStyleLight,
  );

  static ElevatedButtonThemeData get elevatedButtonThemeDark => ElevatedButtonThemeData(
    style: elevatedButtonStyleDark,
  );

  static OutlinedButtonThemeData get outlinedButtonThemeLight => OutlinedButtonThemeData(
    style: outlinedButtonStyleLight,
  );

  static OutlinedButtonThemeData get outlinedButtonThemeDark => OutlinedButtonThemeData(
    style: outlinedButtonStyleDark,
  );

  // Text Themes
  static TextTheme get textThemeLight => GoogleFonts.sourceSans3TextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.bold,
        fontSize: displayLargeSize,
        height: textHeightMultiplier,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.bold,
        fontSize: displayMediumSize,
        height: textHeightMultiplier,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.bold,
        fontSize: headlineLargeSize,
        height: textHeightMultiplier,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        fontSize: headlineMediumSize,
        height: textHeightMultiplier,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        fontSize: titleLargeSize,
        height: textHeightMultiplier,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        fontSize: titleMediumSize,
        height: textHeightMultiplier,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: bodyLargeSize,
        height: textHeightMultiplier,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: bodyMediumSize,
        height: textHeightMultiplier,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        fontSize: labelLargeSize,
        height: textHeightMultiplier,
      ),
    ),
  ).copyWith(
    bodySmall: GoogleFonts.ibmPlexSans(
      color: AppColors.textSecondaryLight,
      fontSize: bodySmallSize,
      height: textHeightMultiplier,
    ),
    labelSmall: GoogleFonts.ibmPlexSans(
      color: AppColors.textSecondaryLight,
      fontSize: labelSmallSize,
      height: textHeightMultiplier,
    ),
  );

  static TextTheme get textThemeDark => GoogleFonts.sourceSans3TextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.bold,
        fontSize: displayLargeSize,
        height: textHeightMultiplier,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.bold,
        fontSize: displayMediumSize,
        height: textHeightMultiplier,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.bold,
        fontSize: headlineLargeSize,
        height: textHeightMultiplier,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
        fontSize: headlineMediumSize,
        height: textHeightMultiplier,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
        fontSize: titleLargeSize,
        height: textHeightMultiplier,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
        fontSize: titleMediumSize,
        height: textHeightMultiplier,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: bodyLargeSize,
        height: textHeightMultiplier,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: bodyMediumSize,
        height: textHeightMultiplier,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
        fontSize: labelLargeSize,
        height: textHeightMultiplier,
      ),
    ),
  ).copyWith(
    bodySmall: GoogleFonts.ibmPlexSans(
      color: AppColors.textSecondaryDark,
      fontSize: bodySmallSize,
      height: textHeightMultiplier,
    ),
    labelSmall: GoogleFonts.ibmPlexSans(
      color: AppColors.textSecondaryDark,
      fontSize: labelSmallSize,
      height: textHeightMultiplier,
    ),
  );

  // Card Themes
  static CardThemeData get cardThemeLight => const CardThemeData(
    color: AppColors.surfaceLight,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  static CardThemeData get cardThemeDark => const CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // Complete Themes
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      // appBarTheme: appBarThemeLight,
      elevatedButtonTheme: elevatedButtonThemeLight,
      outlinedButtonTheme: outlinedButtonThemeLight,
      textTheme: textThemeLight,
      cardTheme: cardThemeLight,
      scaffoldBackgroundColor: AppColors.backgroundLight,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      // appBarTheme: appBarThemeDark,
      elevatedButtonTheme: elevatedButtonThemeLight,
      outlinedButtonTheme: outlinedButtonThemeDark,
      textTheme: textThemeDark,
      cardTheme: cardThemeDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }
}
