import 'package:flutter/material.dart';

/// Design system theme based on design.json tokens
class AppTheme {
  // Color tokens from design.json
  static const Color primary = Color(0xFF1E40AF);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFEA580C);
  static const Color error = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color chipBackground = Color(0xFFEEF2F6);
  static const Color badgeBlue = Color(0xFF3B82F6);
  static const Color divider = Color(0xFFE2E8F0);

  // Font sizes from design.json
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeSubtitle = 16.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeLargeHeading = 28.0;
  static const double badgeFontSize = 10.0;

  // Spacing tokens
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;

  // Border radius tokens
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 20.0;
  static const double badgeRadius = 12.0;
  static const double buttonRadius = 12.0;

  // Shadow tokens
  static const List<BoxShadow> baseShadow = [
    BoxShadow(
      color: Color(0x0D0F172A), // 5% opacity
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> featuredShadow = [
    BoxShadow(
      color: Color(0x1A0F172A), // 10% opacity
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x08000000), // 3% opacity
      offset: Offset(0, -2),
      blurRadius: 10,
    ),
  ];

  // Button padding from design.json
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spacingLG,
    vertical: spacingM,
  );

  // Search bar padding from design.json
  static const EdgeInsets searchBarPadding = EdgeInsets.symmetric(
    horizontal: spacingL,
    vertical: spacingM,
  );

  // Card padding from design.json
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLG);

  // Tab bar height from design.json
  static const double tabBarHeight = 80.0;
  static const EdgeInsets tabBarPadding = EdgeInsets.symmetric(
    vertical: spacingS,
  );

  // Stat card padding from design.json
  static const EdgeInsets statCardPadding = EdgeInsets.all(spacingLG);

  // Bottom navigation bar theme
  static const double bottomNavHeight = 64.0;
  static const double bottomNavIconSize = 24.0;
  static const double bottomNavLabelSize = 12.0;

  static const Color searchBarIconColor = secondary;

  /// Main theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeLargeHeading,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeHeading,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeSubtitle,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeSubtitle,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        shadowColor: textPrimary.withValues(alpha: 0.05),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: borderColor),
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primary),
        ),
        contentPadding: searchBarPadding,
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: fontSizeBody,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: neutral,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: background,
    );
  }

  /// Extension methods for easy access to design tokens
  static EdgeInsets get paddingXS => const EdgeInsets.all(spacingXS);
  static EdgeInsets get paddingS => const EdgeInsets.all(spacingS);
  static EdgeInsets get paddingM => const EdgeInsets.all(spacingM);
  static EdgeInsets get paddingL => const EdgeInsets.all(spacingL);
  static EdgeInsets get paddingLG => const EdgeInsets.all(spacingLG);
  static EdgeInsets get paddingXL => const EdgeInsets.all(spacingXL);
  static EdgeInsets get paddingXXL => const EdgeInsets.all(spacingXXL);

  static EdgeInsets get paddingHorizontalXS =>
      const EdgeInsets.symmetric(horizontal: spacingXS);
  static EdgeInsets get paddingHorizontalS =>
      const EdgeInsets.symmetric(horizontal: spacingS);
  static EdgeInsets get paddingHorizontalM =>
      const EdgeInsets.symmetric(horizontal: spacingM);
  static EdgeInsets get paddingHorizontalL =>
      const EdgeInsets.symmetric(horizontal: spacingL);
  static EdgeInsets get paddingHorizontalXL =>
      const EdgeInsets.symmetric(horizontal: spacingXL);

  static EdgeInsets get paddingVerticalXS =>
      const EdgeInsets.symmetric(vertical: spacingXS);
  static EdgeInsets get paddingVerticalS =>
      const EdgeInsets.symmetric(vertical: spacingS);
  static EdgeInsets get paddingVerticalM =>
      const EdgeInsets.symmetric(vertical: spacingM);
  static EdgeInsets get paddingVerticalL =>
      const EdgeInsets.symmetric(vertical: spacingL);
  static EdgeInsets get paddingVerticalXL =>
      const EdgeInsets.symmetric(vertical: spacingXL);

  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);
}
