import 'package:coopsol_mobile/core/theme/app_theme.dart';
import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:coopsol_mobile/core/widgets/brand_mark.dart';
import 'package:coopsol_mobile/core/widgets/glass_app_bar.dart';
import 'package:coopsol_mobile/core/widgets/glass_background.dart';
import 'package:coopsol_mobile/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpThemed(
  WidgetTester tester,
  Widget home, {
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: home,
    ),
  );
}

void main() {
  group('GlassCard', () {
    testWidgets('shows its child inside a blurred, clipped surface', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const Scaffold(body: GlassCard(child: Text('contenido'))),
      );

      expect(find.text('contenido'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses a radius of 24 and a padding of 24 by default', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const Scaffold(body: GlassCard(child: Text('contenido'))),
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(ClipRRect),
        ),
      );
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('contenido'),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(clip.borderRadius, BorderRadius.circular(24));
      expect(padding.padding, const EdgeInsets.all(24));
    });

    testWidgets('accepts a custom radius and padding', (tester) async {
      await pumpThemed(
        tester,
        const Scaffold(
          body: GlassCard(
            radius: 16,
            padding: EdgeInsets.all(8),
            child: Text('contenido'),
          ),
        ),
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(ClipRRect),
        ),
      );
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('contenido'),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(clip.borderRadius, BorderRadius.circular(16));
      expect(padding.padding, const EdgeInsets.all(8));
    });

    for (final mode in ThemeMode.values.where((m) => m != ThemeMode.system)) {
      testWidgets(
        'paints the translucent fill and border of the $mode tokens',
        (tester) async {
          final tokens = mode == ThemeMode.light
              ? GlassTokens.light
              : GlassTokens.dark;
          await pumpThemed(
            tester,
            const Scaffold(body: GlassCard(child: Text('contenido'))),
            mode: mode,
          );

          final decorated = tester.widget<DecoratedBox>(
            find.descendant(
              of: find.byType(BackdropFilter),
              matching: find.byType(DecoratedBox),
            ),
          );
          final decoration = decorated.decoration as BoxDecoration;

          expect(decoration.color, tokens.cardBackground);
          expect((decoration.border as Border).top.color, tokens.cardBorder);
        },
      );
    }
  });

  group('BrandMark', () {
    testWidgets('shows the CS mark and the product name', (tester) async {
      await pumpThemed(
        tester,
        const Scaffold(body: Center(child: BrandMark())),
      );

      expect(find.text('CS'), findsOneWidget);
      expect(find.text('CoopSol'), findsOneWidget);
    });

    testWidgets('draws the mark as a 32 by 32 square', (tester) async {
      await pumpThemed(
        tester,
        const Scaffold(body: Center(child: BrandMark())),
      );

      expect(
        tester.getSize(find.byKey(const Key('brand-mark'))),
        const Size(32, 32),
      );
    });
  });

  group('GlassAppBar', () {
    testWidgets('shows the brand mark and the given actions', (tester) async {
      await pumpThemed(
        tester,
        Scaffold(
          appBar: GlassAppBar(
            actions: [TextButton(onPressed: () {}, child: const Text('Salir'))],
          ),
        ),
      );

      expect(find.byType(BrandMark), findsOneWidget);
      expect(find.text('Salir'), findsOneWidget);
    });

    testWidgets('blurs what is behind it and has the height of a toolbar', (
      tester,
    ) async {
      await pumpThemed(tester, const Scaffold(appBar: GlassAppBar()));

      expect(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(const GlassAppBar().preferredSize.height, kToolbarHeight);
    });

    testWidgets('does not show a back button', (tester) async {
      await pumpThemed(tester, const Scaffold(appBar: GlassAppBar()));

      expect(find.byType(BackButton), findsNothing);
    });
  });

  group('GlassBackground', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'paints the base gradient of the $mode tokens behind its child',
        (tester) async {
          final tokens = mode == ThemeMode.light
              ? GlassTokens.light
              : GlassTokens.dark;
          await pumpThemed(
            tester,
            const GlassBackground(child: Text('encima')),
            mode: mode,
          );

          final decorated = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(GlassBackground),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final gradient =
              (decorated.decoration as BoxDecoration).gradient
                  as LinearGradient;

          expect(gradient.colors, [tokens.baseStart, tokens.baseEnd]);
          expect(find.text('encima'), findsOneWidget);
        },
      );
    }

    testWidgets('repaints when the glow colors change', (tester) async {
      await pumpThemed(tester, const GlassBackground(child: SizedBox()));
      final light = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(GlassBackground),
          matching: find.byType(CustomPaint),
        ),
      );

      await pumpThemed(
        tester,
        const GlassBackground(child: SizedBox()),
        mode: ThemeMode.dark,
      );
      await tester.pumpAndSettle();
      final dark = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(GlassBackground),
          matching: find.byType(CustomPaint),
        ),
      );

      expect(dark.painter!.shouldRepaint(light.painter!), isTrue);
    });
  });
}
