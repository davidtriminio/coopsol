import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3C6E58),
    onPrimary: Color(0xFFEEF6F1),
    secondary: Color(0xFF3C6E58),
    onSecondary: Color(0xFFEEF6F1),
    error: Color(0xFFA32D2D),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F4EF),
    onSurface: Color(0xFF1C1B18),
    onSurfaceVariant: Color(0xFF6C685F),
    outlineVariant: Color(0x141C1B18),
    surfaceContainerLowest: Color(0xFFFFFFFF),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7FB69C),
    onPrimary: Color(0xFF0E1A15),
    secondary: Color(0xFF7FB69C),
    onSecondary: Color(0xFF0E1A15),
    error: Color(0xFFFF9B9B),
    onError: Color(0xFF1C1B18),
    surface: Color(0xFF15140F),
    onSurface: Color(0xFFF1EFE7),
    onSurfaceVariant: Color(0xFFA49F92),
    outlineVariant: Color(0x1AF1EFE7),
    surfaceContainerLowest: Color(0xFF201F1C),
  );
}
