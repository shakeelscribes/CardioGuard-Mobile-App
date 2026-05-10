import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Dark Theme Colors ──────────────────────────────────────
  static const Color background     = Color(0xFF0F172A);
  static const Color surface        = Color(0xFF111827);
  static const Color surfaceLight   = Color(0xFF1F2937);
  static const Color card           = Color(0xFF1E293B);
  static const Color cardBorder     = Color(0xFF334155);

  static const Color primary        = Color(0xFF2563EB);
  static const Color primaryLight   = Color(0xFF3B82F6);
  static const Color primaryDark    = Color(0xFF1D4ED8);
  static const Color accent         = Color(0xFF7C3AED);
  static const Color accentTeal     = Color(0xFF06B6D4);

  static const Color textPrimary    = Color(0xFFF1F5F9);
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textMuted      = Color(0xFF64748B);

  static const Color success        = Color(0xFF22C55E);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color danger         = Color(0xFFEF4444);
  static const Color divider        = Color(0xFF1E293B);

  // ── Light Theme Colors (improved contrast) ─────────────────
  static const Color lBackground    = Color(0xFFEFF6FF); // soft blue-white
  static const Color lSurface       = Color(0xFFFFFFFF); // pure white
  static const Color lSurfaceLight  = Color(0xFFEEF2FF); // inputs/fields bg
  static const Color lCard          = Color(0xFFFFFFFF); // white cards
  static const Color lCardBorder    = Color(0xFFBFDBFE); // blue-tinted border

  static const Color lPrimary       = Color(0xFF2563EB);
  static const Color lPrimaryLight  = Color(0xFF3B82F6);
  static const Color lPrimaryDark   = Color(0xFF1D4ED8);
  static const Color lAccent        = Color(0xFF7C3AED);
  static const Color lAccentTeal    = Color(0xFF0891B2);

  // ✅ High contrast text for light mode
  static const Color lTextPrimary   = Color(0xFF0F172A); // near black
  static const Color lTextSecondary = Color(0xFF1E3A5F); // dark blue-grey
  static const Color lTextMuted     = Color(0xFF475569); // medium slate

  static const Color lSuccess       = Color(0xFF15803D); // dark green
  static const Color lWarning       = Color(0xFFB45309); // dark amber
  static const Color lDanger        = Color(0xFFB91C1C); // dark red
  static const Color lDivider       = Color(0xFFBFDBFE); // blue-tinted divider

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark bg gradient
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ✅ Light bg gradient — subtle blue-white
  static const LinearGradient lBgGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark card gradient
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Light card gradient — white with subtle tint
  static const LinearGradient lCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lowRiskGradient = LinearGradient(
    colors: [Color(0xFF14532D), Color(0xFF166534)],
  );
  static const LinearGradient mediumRiskGradient = LinearGradient(
    colors: [Color(0xFF78350F), Color(0xFF92400E)],
  );
  static const LinearGradient highRiskGradient = LinearGradient(
    colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
  );
}

// ── Theme Extension ────────────────────────────────────────────
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color card;
  final Color cardBorder;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentTeal;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color divider;
  final LinearGradient bgGradient;
  final LinearGradient cardGradient;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.card,
    required this.cardBorder,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentTeal,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.divider,
    required this.bgGradient,
    required this.cardGradient,
  });

  static const AppThemeColors dark = AppThemeColors(
    background:   AppColors.background,
    surface:      AppColors.surface,
    surfaceLight: AppColors.surfaceLight,
    card:         AppColors.card,
    cardBorder:   AppColors.cardBorder,
    primary:      AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark:  AppColors.primaryDark,
    accent:       AppColors.accent,
    accentTeal:   AppColors.accentTeal,
    textPrimary:  AppColors.textPrimary,
    textSecondary:AppColors.textSecondary,
    textMuted:    AppColors.textMuted,
    success:      AppColors.success,
    warning:      AppColors.warning,
    danger:       AppColors.danger,
    divider:      AppColors.divider,
    bgGradient:   AppColors.bgGradient,
    cardGradient: AppColors.cardGradient,
  );

  static const AppThemeColors light = AppThemeColors(
    background:   AppColors.lBackground,
    surface:      AppColors.lSurface,
    surfaceLight: AppColors.lSurfaceLight,
    card:         AppColors.lCard,
    cardBorder:   AppColors.lCardBorder,
    primary:      AppColors.lPrimary,
    primaryLight: AppColors.lPrimaryLight,
    primaryDark:  AppColors.lPrimaryDark,
    accent:       AppColors.lAccent,
    accentTeal:   AppColors.lAccentTeal,
    textPrimary:  AppColors.lTextPrimary,
    textSecondary:AppColors.lTextSecondary,
    textMuted:    AppColors.lTextMuted,
    success:      AppColors.lSuccess,
    warning:      AppColors.lWarning,
    danger:       AppColors.lDanger,
    divider:      AppColors.lDivider,
    bgGradient:   AppColors.lBgGradient,
    cardGradient: AppColors.lCardGradient,
  );

  @override
  AppThemeColors copyWith({
    Color? background, Color? surface, Color? surfaceLight,
    Color? card, Color? cardBorder, Color? primary, Color? primaryLight,
    Color? primaryDark, Color? accent, Color? accentTeal,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? success, Color? warning, Color? danger, Color? divider,
    LinearGradient? bgGradient, LinearGradient? cardGradient,
  }) =>
      AppThemeColors(
        background:    background    ?? this.background,
        surface:       surface       ?? this.surface,
        surfaceLight:  surfaceLight  ?? this.surfaceLight,
        card:          card          ?? this.card,
        cardBorder:    cardBorder    ?? this.cardBorder,
        primary:       primary       ?? this.primary,
        primaryLight:  primaryLight  ?? this.primaryLight,
        primaryDark:   primaryDark   ?? this.primaryDark,
        accent:        accent        ?? this.accent,
        accentTeal:    accentTeal    ?? this.accentTeal,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted:     textMuted     ?? this.textMuted,
        success:       success       ?? this.success,
        warning:       warning       ?? this.warning,
        danger:        danger        ?? this.danger,
        divider:       divider       ?? this.divider,
        bgGradient:    bgGradient    ?? this.bgGradient,
        cardGradient:  cardGradient  ?? this.cardGradient,
      );

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      surfaceLight:  Color.lerp(surfaceLight,  other.surfaceLight,  t)!,
      card:          Color.lerp(card,          other.card,          t)!,
      cardBorder:    Color.lerp(cardBorder,    other.cardBorder,    t)!,
      primary:       Color.lerp(primary,       other.primary,       t)!,
      primaryLight:  Color.lerp(primaryLight,  other.primaryLight,  t)!,
      primaryDark:   Color.lerp(primaryDark,   other.primaryDark,   t)!,
      accent:        Color.lerp(accent,        other.accent,        t)!,
      accentTeal:    Color.lerp(accentTeal,    other.accentTeal,    t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted,     other.textMuted,     t)!,
      success:       Color.lerp(success,       other.success,       t)!,
      warning:       Color.lerp(warning,       other.warning,       t)!,
      danger:        Color.lerp(danger,        other.danger,        t)!,
      divider:       Color.lerp(divider,       other.divider,       t)!,
      bgGradient:    bgGradient,
      cardGradient:  cardGradient,
    );
  }
}

// ✅ Convenience extension — use context.c.textPrimary anywhere
extension AppThemeX on BuildContext {
  AppThemeColors get c => Theme.of(this).extension<AppThemeColors>()!;
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lBackground,
      colorScheme: const ColorScheme.light(
        primary:   AppColors.lPrimary,
        secondary: AppColors.lAccent,
        surface:   AppColors.lSurface,
      ),
      extensions: const [AppThemeColors.light],
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: AppColors.lTextPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: AppColors.lTextPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: AppColors.lTextPrimary, fontWeight: FontWeight.w600),
          headlineMedium:TextStyle(color: AppColors.lTextPrimary, fontWeight: FontWeight.w600),
          bodyLarge:     TextStyle(color: AppColors.lTextPrimary),
          bodyMedium:    TextStyle(color: AppColors.lTextSecondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.lTextSecondary),
        hintStyle:  const TextStyle(color: AppColors.lTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lCardBorder, width: 1),
        ),
        elevation: 2,
        shadowColor: const Color(0x1A2563EB), // subtle blue shadow
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.accent,
        surface:   AppColors.surface,
      ),
      extensions: const [AppThemeColors.dark],
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          bodyLarge:     TextStyle(color: AppColors.textPrimary),
          bodyMedium:    TextStyle(color: AppColors.textSecondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle:  const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}