import 'package:coopsol_mobile/core/theme/app_theme.dart';
import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light registers the light glass tokens and a light scheme', () {
      final theme = AppTheme.light();

      expect(theme.extension<GlassTokens>(), GlassTokens.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, GlassTokens.light.buttonBackground);
    });

    test('dark registers the dark glass tokens and a dark scheme', () {
      final theme = AppTheme.dark();

      expect(theme.extension<GlassTokens>(), GlassTokens.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, GlassTokens.dark.buttonBackground);
    });

    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      final theme = entry.value;

      test('${entry.key} leaves scaffolds and the app bar transparent', () {
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(theme.appBarTheme.backgroundColor, Colors.transparent);
        expect(theme.appBarTheme.elevation, 0);
      });

      test(
        '${entry.key} uses Sora for titles and IBM Plex Sans for body text',
        () {
          expect(theme.textTheme.titleLarge?.fontFamily, AppTheme.displayFont);
          expect(theme.textTheme.titleMedium?.fontFamily, AppTheme.displayFont);
          expect(
            theme.textTheme.headlineSmall?.fontFamily,
            AppTheme.displayFont,
          );
          expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.bodyFont);
          expect(theme.textTheme.labelLarge?.fontFamily, AppTheme.bodyFont);
        },
      );

      test(
        '${entry.key} uses medium body text and semibold labels and titles',
        () {
          expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w500);
          expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w500);
          expect(theme.textTheme.bodySmall?.fontWeight, FontWeight.w500);
          expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
          expect(theme.textTheme.labelMedium?.fontWeight, FontWeight.w600);
          expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
        },
      );

      test('${entry.key} paints text with the token text color', () {
        final tokens = theme.extension<GlassTokens>()!;

        expect(theme.textTheme.bodyMedium?.color, tokens.text);
        expect(theme.textTheme.titleLarge?.color, tokens.text);
      });

      test(
        '${entry.key} gives inputs translucent fill and rounded borders',
        () {
          final tokens = theme.extension<GlassTokens>()!;
          final inputs = theme.inputDecorationTheme;
          final border = inputs.enabledBorder as OutlineInputBorder;

          expect(inputs.filled, isTrue);
          expect(inputs.fillColor, tokens.fieldBackground);
          expect(border.borderRadius, BorderRadius.circular(10));
          expect(border.borderSide.color, tokens.fieldBorder);
        },
      );

      test(
        '${entry.key} makes filled buttons pills with the button colors',
        () {
          final tokens = theme.extension<GlassTokens>()!;
          final style = theme.filledButtonTheme.style!;

          expect(style.shape?.resolve({}), isA<StadiumBorder>());
          expect(style.backgroundColor?.resolve({}), tokens.buttonBackground);
          expect(style.foregroundColor?.resolve({}), tokens.buttonForeground);
        },
      );
    }
  });
}
