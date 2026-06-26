import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFE8ECF1);
  static const Color surface = Color(0xFFE8ECF1);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textTertiary = Color(0xFF999999);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color accent = Color(0xFF6366F1);
  static const Color pending = Color(0xFF999999);
  static const shadowDark = Color(0x18000000);
  static const shadowLight = Color(0xBBFFFFFF);
}

class AppShadows {
  static const boxShadow = [
    BoxShadow(color: AppColors.shadowDark, blurRadius: 20, offset: Offset(8, 8)),
    BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: Offset(-8, -8)),
  ];

  static const insetShadow = [
    BoxShadow(color: AppColors.shadowDark, blurRadius: 8, offset: Offset(3, 3)),
    BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(-3, -3)),
  ];

  static const buttonShadow = [
    BoxShadow(color: AppColors.shadowDark, blurRadius: 12, offset: Offset(4, 4)),
    BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: Offset(-4, -4)),
  ];

  static const subtleShadow = [
    BoxShadow(color: AppColors.shadowDark, blurRadius: 6, offset: Offset(2, 2)),
    BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: Offset(-2, -2)),
  ];
}

class AppRadii {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 14;
  static const double extraLarge = 20;
  static const double pill = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─── NTheme — runtime theme helper used by widgets ───────────────────────────

class NTheme {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color accent;
  final Color shadowDark;
  final Color shadowLight;
  final List<BoxShadow> boxShadow;
  final List<BoxShadow> insetShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> subtleShadow;

  const NTheme._({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.accent,
    required this.shadowDark,
    required this.shadowLight,
    required this.boxShadow,
    required this.insetShadow,
    required this.buttonShadow,
    required this.subtleShadow,
  });

  static const NTheme _light = NTheme._(
    background: Color(0xFFE8ECF1),
    surface: Color(0xFFE8ECF1),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5A5A5A),
    textTertiary: Color(0xFF999999),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    accent: Color(0xFF6366F1),
    shadowDark: Color(0x18000000),
    shadowLight: Color(0xBBFFFFFF),
    boxShadow: [
      BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(8, 8)),
      BoxShadow(color: Color(0xBBFFFFFF), blurRadius: 20, offset: Offset(-8, -8)),
    ],
    insetShadow: [
      BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(3, 3)),
      BoxShadow(color: Color(0xBBFFFFFF), blurRadius: 8, offset: Offset(-3, -3)),
    ],
    buttonShadow: [
      BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(4, 4)),
      BoxShadow(color: Color(0xBBFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    ],
    subtleShadow: [
      BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(2, 2)),
      BoxShadow(color: Color(0xBBFFFFFF), blurRadius: 6, offset: Offset(-2, -2)),
    ],
  );

  static const NTheme _dark = NTheme._(
    background: Color(0xFF1E2228),
    surface: Color(0xFF1E2228),
    textPrimary: Color(0xFFE8ECF1),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    accent: Color(0xFF818CF8),
    shadowDark: Color(0x40000000),
    shadowLight: Color(0x1AFFFFFF),
    boxShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(8, 8)),
      BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 20, offset: Offset(-8, -8)),
    ],
    insetShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(3, 3)),
      BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 8, offset: Offset(-3, -3)),
    ],
    buttonShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(4, 4)),
      BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    ],
    subtleShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(2, 2)),
      BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 6, offset: Offset(-2, -2)),
    ],
  );

  static NTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

// ─── AppTheme ─────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.success,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.success,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Roboto',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.extraLarge)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.success : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.success.withValues(alpha: 0.3) : AppColors.textTertiary.withValues(alpha: 0.2)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.textTertiary),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E2228),
      primaryColor: AppColors.success,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.success,
        secondary: Color(0xFF818CF8),
        surface: Color(0xFF1E2228),
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E2228),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFE8ECF1)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8ECF1),
          fontFamily: 'Roboto',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E2228),
        selectedItemColor: Color(0xFFE8ECF1),
        unselectedItemColor: Color(0xFF6B7280),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF252A31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.extraLarge)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252A31),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE8ECF1)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.success : const Color(0xFF6B7280)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.success.withValues(alpha: 0.3) : const Color(0xFF6B7280).withValues(alpha: 0.2)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Color(0xFFE8ECF1)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Color(0xFFE8ECF1)),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFFE8ECF1)),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFE8ECF1)),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFFE8ECF1)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE8ECF1)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8ECF1)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE8ECF1)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFE8ECF1)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFE8ECF1)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF9CA3AF)),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Color(0xFF6B7280)),
      ),
    );
  }
}
