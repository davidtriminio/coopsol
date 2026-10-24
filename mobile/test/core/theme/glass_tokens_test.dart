import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b){
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

Color cardOver(GlassTokens tokens, Color backdrop) {
  return Color.alphaBlend(tokens.cardBackground, backdrop);
}

Color fieldOver(GlassTokens tokens, Color backdrop) {
  return Color.alphaBlend(tokens.fieldBackground, cardOver(tokens, backdrop));
}

List<Color> backdrops(GlassTokens tokens) {
  return [tokens.glowTop, tokens.baseStart, tokens.glowBottom];
}

void main(){
  group('contrast of the light palette', () {
    const tokens = GlassTokens.light;

    test('body text is at least 7:1 on the card over every part of the gradient', () {
      for (final backdrop in backdrops(tokens)) {
        expect(contrast(tokens.text, cardOver(tokens, backdrop)), greaterThanOrEqualTo(7));
      }
    });

    test('secondary text is at least 4.5:1 on the card and on the fields', () {
      for (final backdrop in backdrops(tokens)) {
        expect(
          contrast(tokens.textMuted, cardOver(tokens, backdrop)),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(tokens.textMuted, fieldOver(tokens, backdrop)),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('the button label is at least 7:1 on the button', () {
      expect(
        contrast(tokens.buttonForeground, tokens.buttonBackground),
        greaterThanOrEqualTo(7),
      );
    });

    test('the error color is at least 4.5:1 on the card', () {
      for (final backdrop in backdrops(tokens)) {
        expect(contrast(tokens.danger, cardOver(tokens, backdrop)), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('contrast of the dark palette', () {
    const tokens = GlassTokens.dark;

    test('body text is at least 4.5:1 on the card over every part of the gradient', () {
      for (final backdrop in backdrops(tokens)) {
        expect(contrast(tokens.text, cardOver(tokens, backdrop)), greaterThanOrEqualTo(4.5));
      }
    });

    test('secondary text is at least 4.5:1 on the card', () {
      for (final backdrop in backdrops(tokens)) {
        expect(
          contrast(tokens.textMuted, cardOver(tokens, backdrop)),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('field labels stay at least 4:1 over the brightest glow', () {
      for (final backdrop in backdrops(tokens)) {
        expect(
          contrast(tokens.textMuted, fieldOver(tokens, backdrop)),
          greaterThanOrEqualTo(4),
        );
      }
    });

    test('the button label is at least 7:1 on the button', () {
      expect(
        contrast(tokens.buttonForeground, tokens.buttonBackground),
        greaterThanOrEqualTo(7),
      );
    });

    test('the error color is at least 4.5:1 on the card', () {
      for (final backdrop in backdrops(tokens)) {
        expect(contrast(tokens.danger, cardOver(tokens, backdrop)), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('toColorScheme', () {
    test('maps the glass tokens to the Material roles', () {
      final scheme = GlassTokens.light.toColorScheme(Brightness.light);

      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, GlassTokens.light.buttonBackground);
      expect(scheme.onPrimary, GlassTokens.light.buttonForeground);
      expect(scheme.error, GlassTokens.light.danger);
      expect(scheme.onSurface, GlassTokens.light.text);
      expect(scheme.onSurfaceVariant, GlassTokens.light.textMuted);
      expect(scheme.surface, GlassTokens.light.baseStart);
    });

    test('keeps the dark brightness and a readable error label', () {
      final scheme = GlassTokens.dark.toColorScheme(Brightness.dark);

      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, GlassTokens.dark.buttonBackground);
      expect(contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
    });
  });

  group('copyWith and lerp', () {
    test('copyWith replaces only the given token', () {
      final changed = GlassTokens.light.copyWith(danger: Colors.black);

      expect(changed.danger, Colors.black);
      expect(changed.text, GlassTokens.light.text);
      expect(changed.glowTop, GlassTokens.light.glowTop);
    });

    test('lerp returns each end at 0 and 1 and a blend in between', () {
      final start = GlassTokens.light.lerp(GlassTokens.dark, 0);
      final end = GlassTokens.light.lerp(GlassTokens.dark, 1);
      final middle = GlassTokens.light.lerp(GlassTokens.dark, 0.5);

      expect(start.text, GlassTokens.light.text);
      expect(end.text, GlassTokens.dark.text);
      expect(middle.text, Color.lerp(GlassTokens.light.text, GlassTokens.dark.text, 0.5));
    });

    test('lerp ignores an extension of another type', () {
      expect(GlassTokens.light.lerp(null, 0.5), GlassTokens.light);
    });
  });

  group('GlassTokens.of', () {
    Future<GlassTokens> readTokens(WidgetTester tester, ThemeData theme) async {
      late GlassTokens read;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              read = GlassTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return read;
    }

    testWidgets('returns the tokens registered in the theme', (tester) async {
      final custom = GlassTokens.light.copyWith(text: Colors.red);

      final read = await readTokens(
        tester,
        ThemeData(extensions: <ThemeExtension<dynamic>>[custom]),
      );

      expect(read.text, Colors.red);
    });

    testWidgets('falls back to the light tokens when the theme has none', (tester) async {
      final read = await readTokens(tester, ThemeData(brightness: Brightness.light));

      expect(read.text, GlassTokens.light.text);
    });

    testWidgets('falls back to the dark tokens in a dark theme without them', (tester) async {
      final read = await readTokens(tester, ThemeData(brightness: Brightness.dark));

      expect(read.text, GlassTokens.dark.text);
    });
  });
}