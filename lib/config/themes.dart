import 'package:flutter/material.dart';
import 'package:muslimdigest/config/constants.dart';
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
  static const double titleSmallSize = 16;
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
  static ColorScheme _buildColorScheme({
    required Brightness brightness,
    required Color surface,
    required Color surfaceContainerHigh,
    required Color surfaceContainerHighest,
    required Color onSurface,
    required Color outline,
    required Color tertiary,
  }) {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: surface,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurface,
      onError: Colors.white,
      outline: outline,
      tertiary: tertiary,
    );
  }

  static ColorScheme get lightColorScheme => _buildColorScheme(
    brightness: Brightness.light,
    surface: AppColors.surfaceLight,
    surfaceContainerHigh: AppColors.surfaceContainerHighLight,
    surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
    onSurface: AppColors.textPrimaryLight,
    outline: Colors.grey[200]!,
    tertiary: AppColors.mutedLight,
  );

  static ColorScheme get darkColorScheme => _buildColorScheme(
    brightness: Brightness.dark,
    surface: AppColors.surfaceDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    onSurface: AppColors.textPrimaryDark,
    outline: Colors.grey[800]!,
    tertiary: AppColors.mutedDark,
  );

  // Button Styles
  static ButtonStyle _buildBaseButtonStyle({
    Color? backgroundColor,
    required Color foregroundColor,
    Color? sideColor,
    EdgeInsets? padding,
  }) {
    if (sideColor != null) {
      return OutlinedButton.styleFrom(
        side: BorderSide(color: sideColor),
        foregroundColor: foregroundColor,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontFamily: APP_FONT_FAMILY,
          fontWeight: FontWeight.w500,
          fontSize: buttonLargeSize,
        ),
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontFamily: APP_FONT_FAMILY,
          fontWeight: FontWeight.w500,
          fontSize: buttonLargeSize,
        ),
      );
    }
  }

  static ButtonStyle get elevatedButtonStyleLight => _buildBaseButtonStyle(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  );

  static ButtonStyle get elevatedButtonStyleDark => elevatedButtonStyleLight.copyWith(
    backgroundColor: WidgetStateProperty.all(Colors.white),
    foregroundColor: WidgetStateProperty.all(AppColors.primary),
  );

  static ButtonStyle get outlinedButtonStyleLight => _buildBaseButtonStyle(
    sideColor: AppColors.primary,
    foregroundColor: AppColors.primary,
  );

  static ButtonStyle get outlinedButtonStyleDark => outlinedButtonStyleLight.copyWith(
    side: WidgetStateProperty.all(const BorderSide(color: Colors.white)),
    foregroundColor: WidgetStateProperty.all(Colors.white),
  );

  // Button Themes
  static ElevatedButtonThemeData _buildElevatedButtonTheme(ButtonStyle style) => 
      ElevatedButtonThemeData(style: style);
  
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ButtonStyle style) => 
      OutlinedButtonThemeData(style: style);

  static ElevatedButtonThemeData get elevatedButtonThemeLight => 
      _buildElevatedButtonTheme(elevatedButtonStyleLight);

  static ElevatedButtonThemeData get elevatedButtonThemeDark => 
      _buildElevatedButtonTheme(elevatedButtonStyleDark);

  static OutlinedButtonThemeData get outlinedButtonThemeLight => 
      _buildOutlinedButtonTheme(outlinedButtonStyleLight);

  static OutlinedButtonThemeData get outlinedButtonThemeDark => 
      _buildOutlinedButtonTheme(outlinedButtonStyleDark);

  // Text Themes
  static TextTheme get textThemeLight => _buildTextTheme(
    primaryColor: AppColors.textPrimaryLight,
    secondaryColor: AppColors.textSecondaryLight,
  );

  static TextTheme get textThemeDark => _buildTextTheme(
    primaryColor: AppColors.textPrimaryDark,
    secondaryColor: AppColors.textSecondaryDark,
  );

  static TextTheme _buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return TextTheme(
      displayLarge: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: displayLargeSize,
      ),
      displayMedium: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: displayMediumSize,
      ),
      headlineLarge: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: headlineLargeSize,
      ),
      headlineMedium: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: headlineMediumSize,
      ),
      titleLarge: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: titleLargeSize,
      ),
      titleMedium: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: titleMediumSize,
      ),
      titleSmall: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: titleSmallSize,
      ),
      bodyLarge: _buildTextStyle(
        color: primaryColor,
        fontSize: bodyLargeSize,
      ),
      bodyMedium: _buildTextStyle(
        color: secondaryColor,
        fontSize: bodyMediumSize,
      ),
      bodySmall: _buildTextStyle(
        color: secondaryColor,
        fontSize: bodySmallSize,
      ),
      labelLarge: _buildTextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: labelLargeSize,
      ),
      labelSmall: _buildTextStyle(
        color: secondaryColor,
        fontSize: labelSmallSize,
      ),
    );
  }

  static TextStyle _buildTextStyle({
    required Color color,
    FontWeight? fontWeight,
    required double fontSize,
  }) {
    return TextStyle(
      fontFamily: APP_FONT_FAMILY,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: textHeightMultiplier,
      color: color,
    );
  }

  // Card Themes
  static CardThemeData get _baseCardTheme => const CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // Card Themes
  static CardThemeData _buildCardTheme(Color color) => _baseCardTheme.copyWith(color: color);

  static CardThemeData get cardThemeLight => _buildCardTheme(AppColors.surfaceLight);
  static CardThemeData get cardThemeDark => _buildCardTheme(AppColors.surfaceDark);

  // Base Theme - Common properties for both light and dark themes
  static ThemeData get _baseTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: APP_FONT_FAMILY,
    );
  }

  // Complete Themes
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required OutlinedButtonThemeData outlinedButtonTheme,
    required TextTheme textTheme,
    required CardThemeData cardTheme,
    required Color scaffoldBackgroundColor,
    required ElevatedButtonThemeData elevatedButtonTheme,
  }) {
    return _baseTheme.copyWith(
      colorScheme: colorScheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textTheme: textTheme,
      cardTheme: cardTheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      elevatedButtonTheme: elevatedButtonTheme,
    );
  }

  static ThemeData get lightTheme => _buildTheme(
    colorScheme: lightColorScheme,
    outlinedButtonTheme: outlinedButtonThemeLight,
    textTheme: textThemeLight,
    cardTheme: cardThemeLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    elevatedButtonTheme: elevatedButtonThemeLight,
  );

  static ThemeData get darkTheme => _buildTheme(
    colorScheme: darkColorScheme,
    outlinedButtonTheme: outlinedButtonThemeDark,
    textTheme: textThemeDark,
    cardTheme: cardThemeDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    elevatedButtonTheme: elevatedButtonThemeDark,
  );
}
