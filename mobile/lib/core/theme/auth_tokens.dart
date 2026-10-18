import 'package:flutter/material.dart';

@immutable
class AuthTokens extends ThemeExtension<AuthTokens> {
  const AuthTokens({
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

  static const AuthTokens light = AuthTokens(
    glowTop: Color(0xFF8FD4D9),
    glowBottom: Color(0xFF9AA4F2),
    baseStart: Color(0xFFCDEEF0),
    baseEnd: Color(0xFFCFD3F7),
    cardBackground: Color(0x8CFFFFFF),
    cardBorder: Color(0xB3FFFFFF),
    cardShadow: Color(0x1F0F3A3D),
    text: Color(0xFF0F3A3D),
    textMuted: Color(0xFF3D6467),
    fieldBackground: Color(0x99FFFFFF),
    fieldBorder: Color(0x1F0F3A3D),
    buttonBackground: Color(0xFF0F3A3D),
    buttonForeground: Color(0xFFEAFBF8),
    danger: Color(0xFFA32D2D),
  );
  static const AuthTokens dark = AuthTokens(
    glowTop: Color(0xFF4B3FAE),
    glowBottom: Color(0xFF7A2F6B),
    baseStart: Color(0xFF1A1330),
    baseEnd: Color(0xFF100B1E),
    cardBackground: Color(0x12FFFFFF),
    cardBorder: Color(0x24FFFFFF),
    cardShadow: Color(0x59000000),
    text: Color(0xFFF2EFFF),
    textMuted: Color(0xFFB7AEE0),
    fieldBackground: Color(0x0FFFFFFF),
    fieldBorder: Color(0x24FFFFFF),
    buttonBackground: Color(0xFFB2A1FF),
    buttonForeground: Color(0xFF1C1436),
    danger: Color(0xFFFF9B9B),
  );

  @override
  AuthTokens copyWith({
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
  }) {
    return AuthTokens(
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
  AuthTokens lerp(ThemeExtension<AuthTokens>? other, double t){
    if(other is! AuthTokens) {
      return this;
    }
    return AuthTokens(
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
      buttonBackground: Color.lerp(buttonBackground, other.buttonBackground, t)!,
      buttonForeground: Color.lerp(buttonForeground, other.buttonForeground, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
