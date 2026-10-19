import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const String displayFont = 'Sora';
  static const String bodyFont = 'IBMPlexSans';

  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: displayFont,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: bodyFont,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFont,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  static ThemeData light() => _build(GlassTokens.light, Brightness.light);

  static ThemeData dark() => _build(GlassTokens.dark, Brightness.dark);

  static ThemeData _build(GlassTokens glass, Brightness brightness) {
    final scheme = glass.toColorScheme(brightness);
    final textTheme = _textTheme.apply(
      bodyColor: glass.text,
      displayColor: glass.text,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: glass.fieldBorder),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: bodyFont,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[glass],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: glass.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        systemOverlayStyle:
            (brightness == Brightness.light
                    ? SystemUiOverlayStyle.dark
                    : SystemUiOverlayStyle.light)
                .copyWith(statusBarColor: Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: glass.text, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: glass.danger),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: glass.danger, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: glass.textMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: glass.text),
        errorStyle: textTheme.bodySmall?.copyWith(color: glass.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: glass.buttonBackground,
          foregroundColor: glass.buttonForeground,
          shape: const StadiumBorder(),
          minimumSize: const Size(140, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: glass.text,
          shape: const StadiumBorder(),
          textStyle: textTheme.labelMedium,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: glass.text),
    );
  }
}
