import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Espacements et rayons : à utiliser partout à la place de valeurs en dur.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
}

/// Couleurs sémantiques accessibles via `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.surfaceHigh,
    required this.line,
    required this.textDim,
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
  });

  final Color surfaceHigh;
  final Color line;
  final Color textDim;
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;

  @override
  AppTokens copyWith({
    Color? surfaceHigh,
    Color? line,
    Color? textDim,
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
  }) {
    return AppTokens(
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      line: line ?? this.line,
      textDim: textDim ?? this.textDim,
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      line: Color.lerp(line, other.line, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

class _Palette {
  const _Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.text,
    required this.textDim,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color line;
  final Color text;
  final Color textDim;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;

  /// "Stade de nuit" : fond vert-noir, craie, or du maillot.
  static const dark = _Palette(
    brightness: Brightness.dark,
    bg: Color(0xFF0A1511),
    surface: Color(0xFF12241C),
    surfaceHigh: Color(0xFF1B3328),
    line: Color(0xFF2B4A3B),
    text: Color(0xFFF1EEE3),
    textDim: Color(0xFF9DB0A4),
    accent: Color(0xFFF2B705),
    onAccent: Color(0xFF1A1400),
    success: Color(0xFF3DDC84),
    info: Color(0xFF5BC0EB),
    warning: Color(0xFFFF9F1C),
    danger: Color(0xFFFF5A5F),
  );

  /// Version claire : papier crème, vert gazon profond comme accent.
  static const light = _Palette(
    brightness: Brightness.light,
    bg: Color(0xFFF4F1E8),
    surface: Color(0xFFFBF9F3),
    surfaceHigh: Color(0xFFE9E5D8),
    line: Color(0xFFD3CEBD),
    text: Color(0xFF10201A),
    textDim: Color(0xFF5B6B62),
    accent: Color(0xFF0F6B43),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1E8E54),
    info: Color(0xFF1B76A6),
    warning: Color(0xFFB86E00),
    danger: Color(0xFFC62F3B),
  );
}

abstract final class AppTheme {
  static ThemeData dark() => _build(_Palette.dark);
  static ThemeData light() => _build(_Palette.light);

  static TextTheme _textTheme(_Palette p) {
    final base = GoogleFonts.barlowTextTheme(
      ThemeData(brightness: p.brightness).textTheme,
    ).apply(bodyColor: p.text, displayColor: p.text);

    TextStyle display(double size, [FontWeight weight = FontWeight.w700]) {
      return GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: 0.4,
        color: p.text,
      );
    }

    return base.copyWith(
      displayLarge: display(72, FontWeight.w800),
      displayMedium: display(56, FontWeight.w800),
      displaySmall: display(44, FontWeight.w800),
      headlineLarge: display(36),
      headlineMedium: display(30),
      headlineSmall: display(26),
      titleLarge: display(22, FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: p.textDim,
      ),
      bodySmall: base.bodySmall?.copyWith(color: p.textDim),
    );
  }

  static ThemeData _build(_Palette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.success,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.surfaceHigh,
      onSurfaceVariant: p.textDim,
      outline: p.line,
      outlineVariant: p.line,
    );

    final text = _textTheme(p);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final buttonText = GoogleFonts.barlowCondensed(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.textDim),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.line),
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: buttonText,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.surfaceHigh,
        checkmarkColor: p.accent,
        side: BorderSide(color: p.line),
        labelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.surfaceHigh,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.accent : p.textDim,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.surfaceHigh,
        selectedIconTheme: IconThemeData(color: p.accent),
        unselectedIconTheme: IconThemeData(color: p.textDim),
        selectedLabelTextStyle: GoogleFonts.barlow(
          color: p.accent,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: GoogleFonts.barlow(color: p.textDim),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHigh,
        contentTextStyle: TextStyle(color: p.text),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      extensions: [
        AppTokens(
          surfaceHigh: p.surfaceHigh,
          line: p.line,
          textDim: p.textDim,
          success: p.success,
          info: p.info,
          warning: p.warning,
          danger: p.danger,
        ),
      ],
    );
  }
}
