import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AeroTheme extends ThemeExtension<AeroTheme> {
  final Color bgDark;
  final Color bgDeepNavy;
  final Color bgSurface;
  final Color bgMid;

  final Color glassSurface;
  final Color glassSurfaceMid;
  final Color glassSurfaceHigh;
  final Color glassBorder;
  final Color glassBorderBright;

  final Color cardBg;
  final Color cardBorder;
  final Color cardHover;

  final Color primaryEmerald;
  final Color glowEmerald;
  final Color accentCyan;
  final Color glowCyan;
  final Color accentIndigo;
  final Color accentViolet;
  final Color accentAmber;

  final Color aqiGood;
  final Color aqiSatisfactory;
  final Color aqiModerate;
  final Color aqiPoor;
  final Color aqiVeryPoor;
  final Color aqiSevere;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AeroTheme({
    required this.bgDark,
    required this.bgDeepNavy,
    required this.bgSurface,
    required this.bgMid,
    required this.glassSurface,
    required this.glassSurfaceMid,
    required this.glassSurfaceHigh,
    required this.glassBorder,
    required this.glassBorderBright,
    required this.cardBg,
    required this.cardBorder,
    required this.cardHover,
    required this.primaryEmerald,
    required this.glowEmerald,
    required this.accentCyan,
    required this.glowCyan,
    required this.accentIndigo,
    required this.accentViolet,
    required this.accentAmber,
    required this.aqiGood,
    required this.aqiSatisfactory,
    required this.aqiModerate,
    required this.aqiPoor,
    required this.aqiVeryPoor,
    required this.aqiSevere,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  ThemeExtension<AeroTheme> copyWith({
    Color? bgDark,
    Color? bgDeepNavy,
    Color? bgSurface,
    Color? bgMid,
    Color? glassSurface,
    Color? glassSurfaceMid,
    Color? glassSurfaceHigh,
    Color? glassBorder,
    Color? glassBorderBright,
    Color? cardBg,
    Color? cardBorder,
    Color? cardHover,
    Color? primaryEmerald,
    Color? glowEmerald,
    Color? accentCyan,
    Color? glowCyan,
    Color? accentIndigo,
    Color? accentViolet,
    Color? accentAmber,
    Color? aqiGood,
    Color? aqiSatisfactory,
    Color? aqiModerate,
    Color? aqiPoor,
    Color? aqiVeryPoor,
    Color? aqiSevere,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AeroTheme(
      bgDark: bgDark ?? this.bgDark,
      bgDeepNavy: bgDeepNavy ?? this.bgDeepNavy,
      bgSurface: bgSurface ?? this.bgSurface,
      bgMid: bgMid ?? this.bgMid,
      glassSurface: glassSurface ?? this.glassSurface,
      glassSurfaceMid: glassSurfaceMid ?? this.glassSurfaceMid,
      glassSurfaceHigh: glassSurfaceHigh ?? this.glassSurfaceHigh,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBorderBright: glassBorderBright ?? this.glassBorderBright,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      cardHover: cardHover ?? this.cardHover,
      primaryEmerald: primaryEmerald ?? this.primaryEmerald,
      glowEmerald: glowEmerald ?? this.glowEmerald,
      accentCyan: accentCyan ?? this.accentCyan,
      glowCyan: glowCyan ?? this.glowCyan,
      accentIndigo: accentIndigo ?? this.accentIndigo,
      accentViolet: accentViolet ?? this.accentViolet,
      accentAmber: accentAmber ?? this.accentAmber,
      aqiGood: aqiGood ?? this.aqiGood,
      aqiSatisfactory: aqiSatisfactory ?? this.aqiSatisfactory,
      aqiModerate: aqiModerate ?? this.aqiModerate,
      aqiPoor: aqiPoor ?? this.aqiPoor,
      aqiVeryPoor: aqiVeryPoor ?? this.aqiVeryPoor,
      aqiSevere: aqiSevere ?? this.aqiSevere,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<AeroTheme> lerp(ThemeExtension<AeroTheme>? other, double t) {
    if (other is! AeroTheme) return this;
    return AeroTheme(
      bgDark: Color.lerp(bgDark, other.bgDark, t)!,
      bgDeepNavy: Color.lerp(bgDeepNavy, other.bgDeepNavy, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgMid: Color.lerp(bgMid, other.bgMid, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassSurfaceMid: Color.lerp(glassSurfaceMid, other.glassSurfaceMid, t)!,
      glassSurfaceHigh: Color.lerp(glassSurfaceHigh, other.glassSurfaceHigh, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderBright: Color.lerp(glassBorderBright, other.glassBorderBright, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      primaryEmerald: Color.lerp(primaryEmerald, other.primaryEmerald, t)!,
      glowEmerald: Color.lerp(glowEmerald, other.glowEmerald, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      glowCyan: Color.lerp(glowCyan, other.glowCyan, t)!,
      accentIndigo: Color.lerp(accentIndigo, other.accentIndigo, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      aqiGood: Color.lerp(aqiGood, other.aqiGood, t)!,
      aqiSatisfactory: Color.lerp(aqiSatisfactory, other.aqiSatisfactory, t)!,
      aqiModerate: Color.lerp(aqiModerate, other.aqiModerate, t)!,
      aqiPoor: Color.lerp(aqiPoor, other.aqiPoor, t)!,
      aqiVeryPoor: Color.lerp(aqiVeryPoor, other.aqiVeryPoor, t)!,
      aqiSevere: Color.lerp(aqiSevere, other.aqiSevere, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }

  // Helpers
  static Color getAqiColor(int aqi) {
    if (aqi <= 50)  return AeroTheme.dark.aqiGood;
    if (aqi <= 100) return AeroTheme.dark.aqiSatisfactory;
    if (aqi <= 200) return AeroTheme.dark.aqiModerate;
    if (aqi <= 300) return AeroTheme.dark.aqiPoor;
    if (aqi <= 400) return AeroTheme.dark.aqiVeryPoor;
    return AeroTheme.dark.aqiSevere;
  }

  static String getAqiCategory(int aqi) {
    if (aqi <= 50)  return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }

  static String getSourceIcon(String source) {
    switch (source) {
      case 'Traffic Exhaust':   return '🚗';
      case 'Garbage Burning':   return '🔥';
      case 'Construction Dust': return '🏗️';
      case 'Cooking Smoke':     return '🍳';
      case 'Crop Residue':      return '🌾';
      case 'Clean Baseline':
      default:                  return '🌿';
    }
  }

  BoxDecoration glassCardDecoration({
    Color? borderColor,
    double borderRadius = 20.0,
    bool glow = false,
    Color? glowColor,
    double glowIntensity = 0.22,
    Color? fillColor,
  }) {
    final isLight = bgDark.computeLuminance() > 0.5;
    return BoxDecoration(
      gradient: fillColor != null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glassSurfaceMid,
                glassSurface,
              ],
            ),
      color: fillColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorder,
        width: 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.22),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.08),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
        if (glow && glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: isLight ? glowIntensity * 0.5 : glowIntensity),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        if (glow && glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: (isLight ? glowIntensity * 0.5 : glowIntensity) * 0.5),
            blurRadius: 60,
            spreadRadius: 4,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  BoxDecoration deepCardDecoration({
    Color? borderColor,
    double borderRadius = 24.0,
    Color? glowColor,
    double glowIntensity = 0.28,
  }) {
    final isLight = bgDark.computeLuminance() > 0.5;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassSurfaceHigh,
          glassSurfaceMid,
          glassSurface,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorderBright,
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.25),
          blurRadius: 36,
          spreadRadius: -4,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: isLight ? glowIntensity * 0.5 : glowIntensity),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: (isLight ? glowIntensity * 0.5 : glowIntensity) * 0.4),
            blurRadius: 80,
            spreadRadius: 6,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  static const dark = AeroTheme(
    bgDark: Color(0xFF070B14),
    bgDeepNavy: Color(0xFF0C1220),
    bgSurface: Color(0xFF10192C),
    bgMid: Color(0xFF16233B),
    glassSurface: Color(0x18FFFFFF),
    glassSurfaceMid: Color(0x22FFFFFF),
    glassSurfaceHigh: Color(0x2EFFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassBorderBright: Color(0x38FFFFFF),
    cardBg: Color(0xFF0D1527),
    cardBorder: Color(0x24FFFFFF),
    cardHover: Color(0xFF16223B),
    primaryEmerald: Color(0xFF00F5A0),
    glowEmerald: Color(0xFF00D9F5),
    accentCyan: Color(0xFF00D4FF),
    glowCyan: Color(0xFF38BDF8),
    accentIndigo: Color(0xFF6366F1),
    accentViolet: Color(0xFFA855F7),
    accentAmber: Color(0xFFFBBF24),
    aqiGood: Color(0xFF00F5A0),
    aqiSatisfactory: Color(0xFF84CC16),
    aqiModerate: Color(0xFFFBBF24),
    aqiPoor: Color(0xFFFB923C),
    aqiVeryPoor: Color(0xFFF43F5E),
    aqiSevere: Color(0xFFA855F7),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
  );

  static const light = AeroTheme(
    bgDark: Color(0xFFF1F5F9),
    bgDeepNavy: Color(0xFFE2E8F0),
    bgSurface: Color(0xFFFFFFFF),
    bgMid: Color(0xFFF8FAFC),
    glassSurface: Color(0xE6FFFFFF),
    glassSurfaceMid: Color(0xF2FFFFFF),
    glassSurfaceHigh: Color(0xFAFFFFFF),
    glassBorder: Color(0x1F0F172A),
    glassBorderBright: Color(0x330F172A),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0x1F0F172A),
    cardHover: Color(0xFFF8FAFC),
    primaryEmerald: Color(0xFF059669),
    glowEmerald: Color(0xFF10B981),
    accentCyan: Color(0xFF0284C7),
    glowCyan: Color(0xFF0EA5E9),
    accentIndigo: Color(0xFF4F46E5),
    accentViolet: Color(0xFF7C3AED),
    accentAmber: Color(0xFFD97706),
    aqiGood: Color(0xFF059669),
    aqiSatisfactory: Color(0xFF65A30D),
    aqiModerate: Color(0xFFD97706),
    aqiPoor: Color(0xFFEA580C),
    aqiVeryPoor: Color(0xFFBE123C),
    aqiSevere: Color(0xFF7E22CE),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
  );
}

class AppTheme {
  // Legacy constants for backwards compat during migration, mapped to dark defaults.
  // DO NOT USE THESE FOR NEW WIDGETS. USE: Theme.of(context).extension<AeroTheme>()!
  static const Color bgDark = Color(0xFF050B18);
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color aqiVeryPoor = Color(0xFFEF4444);
  static const Color aqiPoor = Color(0xFFF97316);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AeroTheme.dark.bgDark,
      primaryColor: AeroTheme.dark.primaryEmerald,
      cardColor: AeroTheme.dark.cardBg,
      colorScheme: ColorScheme.dark(
        primary: AeroTheme.dark.primaryEmerald,
        secondary: AeroTheme.dark.accentCyan,
        surface: AeroTheme.dark.bgSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AeroTheme.dark,
      ],
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(color: AeroTheme.dark.textPrimary, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: AeroTheme.dark.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: AeroTheme.dark.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AeroTheme.dark.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AeroTheme.dark.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AeroTheme.dark.textSecondary),
          bodyMedium: TextStyle(color: AeroTheme.dark.textSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AeroTheme.dark.textPrimary,
        ),
        iconTheme: IconThemeData(color: AeroTheme.dark.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AeroTheme.dark.primaryEmerald.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AeroTheme.dark.primaryEmerald,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AeroTheme.dark.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AeroTheme.dark.primaryEmerald, size: 24);
          }
          return IconThemeData(color: AeroTheme.dark.textMuted, size: 22);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: AeroTheme.dark.glassBorder,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AeroTheme.light.bgDark,
      primaryColor: AeroTheme.light.primaryEmerald,
      cardColor: AeroTheme.light.cardBg,
      colorScheme: ColorScheme.light(
        primary: AeroTheme.light.primaryEmerald,
        secondary: AeroTheme.light.accentCyan,
        surface: AeroTheme.light.bgSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AeroTheme.light,
      ],
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: TextStyle(color: AeroTheme.light.textPrimary, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: AeroTheme.light.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: AeroTheme.light.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AeroTheme.light.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AeroTheme.light.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AeroTheme.light.textSecondary),
          bodyMedium: TextStyle(color: AeroTheme.light.textSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AeroTheme.light.textPrimary,
        ),
        iconTheme: IconThemeData(color: AeroTheme.light.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AeroTheme.light.primaryEmerald.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AeroTheme.light.primaryEmerald,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AeroTheme.light.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AeroTheme.light.primaryEmerald, size: 24);
          }
          return IconThemeData(color: AeroTheme.light.textSecondary, size: 22);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: AeroTheme.light.glassBorder,
    );
  }
}
