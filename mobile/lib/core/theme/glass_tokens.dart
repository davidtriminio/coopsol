import 'package:flutter/material.dart';

@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.glowTop,
    required this.glowBottom,
    required this.baseStart,
    required this.baseEnd,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.text,
    required this.textMuted,
    required this.fieldBackground,
    required this.fieldBorder,
    required this.buttonBackground,
    required this.buttonForeground,
    required this.danger,
  });

  final Color glowTop;
  final Color glowBottom;
  final Color baseStart;
  final Color baseEnd;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color text;
  final Color textMuted;
  final Color fieldBackground;
  final Color fieldBorder;
  final Color buttonBackground;
  final Color buttonForeground;
  final Color danger;

  static const GlassTokens light = GlassTokens(
    glowTop: Color(0xFFA99BF0),
    glowBottom: Color(0xFFE6A3D8),
    baseStart: Color(0xFFECE7FF),
    baseEnd: Color(0xFFF6E8F8),
    cardBackground: Color(0x8CFFFFFF),
    cardBorder: Color(0xB3FFFFFF),
    cardShadow: Color(0x2E3D32A0),
    text: Color(0xFF1C1436),
    textMuted: Color(0xFF4A3F7A),
    fieldBackground: Color(0x99FFFFFF),
    fieldBorder: Color(0x381C1436),
    buttonBackground: Color(0xFF3D32A0),
    buttonForeground: Color(0xFFF2EFFF),
    danger: Color(0xFFB3261E),
  );
  static const GlassTokens dark = GlassTokens(
    glowTop: Color(0xFF4B3FAE),
    glowBottom: Color(0xFF7A2F6B),
    baseStart: Color(0xFF1A1330),
    baseEnd: Color(0xFF100B1E),
    cardBackground: Color(0x12FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    cardShadow: Color(0x59000000),
    text: Color(0xFFF5F2FF),
    textMuted: Color(0xFFD9D2FA),
    fieldBackground: Color(0x0FFFFFFF),
    fieldBorder: Color(0x47FFFFFF),
    buttonBackground: Color(0xFFB2A1FF),
    buttonForeground: Color(0xFF1C1436),
    danger: Color(0xFFFFC8C8),
  );

  static GlassTokens of(BuildContext context){
    final theme = Theme.of(context);
    return theme.extension<GlassTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  ColorScheme toColorScheme(Brightness brightness){
    return ColorScheme(
      brightness: brightness,
      primary: buttonBackground,
      onPrimary: buttonForeground,
      secondary: buttonBackground,
      onSecondary: buttonForeground,
      error: danger,
      onError: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1C1436),
      surface: baseStart,
      onSurface: text,
      onSurfaceVariant: textMuted,
      outlineVariant: fieldBorder,
    );
  }

    @override
    GlassTokens copyWith({
      Color? glowTop,
      Color? glowBottom,
      Color? baseStart,
      Color? baseEnd,
      Color? cardBackground,
      Color? cardBorder,
      Color? cardShadow,
      Color? text,
      Color? textMuted,
      Color? fieldBackground,
      Color? fieldBorder,
      Color? buttonBackground,
      Color? buttonForeground,
      Color? danger,
    }){
    return GlassTokens(
      glowTop: glowTop ?? this.glowTop,
      glowBottom: glowBottom ?? this.glowBottom,
      baseStart: baseStart ?? this.baseStart,
      baseEnd: baseEnd ?? this.baseEnd,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonForeground: buttonForeground ?? this.buttonForeground,
      danger: danger ?? this.danger,
    );
    }

    @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
      if (other is! GlassTokens) {
        return this;
      }
      return GlassTokens(
        glowTop: Color.lerp(glowTop, other.glowTop, t)!,
        glowBottom: Color.lerp(glowBottom, other.glowBottom, t)!,
        baseStart: Color.lerp(baseStart, other.baseStart, t)!,
        baseEnd: Color.lerp(baseEnd, other.baseEnd, t)!,
        cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
        cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
        cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
        text: Color.lerp(text, other.text, t)!,
        textMuted: Color.lerp(textMuted, other.textMuted, t)!,
        fieldBackground: Color.lerp(fieldBackground, other.fieldBackground, t)!,
        fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
        buttonBackground: Color.lerp(
            buttonBackground, other.buttonBackground, t)!,
        buttonForeground: Color.lerp(
            buttonForeground, other.buttonForeground, t)!,
        danger: Color.lerp(danger, other.danger, t)!,
      );
    }
}
