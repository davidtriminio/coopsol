import 'package:coopsol_mobile/app.dart';
import 'package:coopsol_mobile/core/app_dependencies.dart';
import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:coopsol_mobile/core/theme/app_theme.dart';
import 'package:coopsol_mobile/core/widgets/brand_mark.dart';
import 'package:coopsol_mobile/core/widgets/glass_app_bar.dart';
import 'package:coopsol_mobile/core/widgets/glass_background.dart';
import 'package:coopsol_mobile/core/widgets/glass_card.dart';
import 'package:coopsol_mobile/features/home/home_page.dart';
import 'package:coopsol_mobile/features/login/login_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http.dart';

void main() {
  late AuthService authService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final store = TokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeAdapter(
            (options) => ResponseBody.fromString('', 204),
      );
    final api = AuthApiService(dio);
    authService = AuthService(api, store, RefreshCoordinator(api, store));
  });

  Future<void> pumpThemed(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.light(), darkTheme: AppTheme.dark(), home: home),
    );
  }

  group('login screen', () {
    testWidgets('puts the form inside a glass card with the brand mark', (
        tester,) async {
      await pumpThemed(tester, LoginPage(authService: authService));

      expect(find.byType(GlassCard), findsOneWidget);
      expect(find.byType(BrandMark), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byKey(const Key('login-submit')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byKey(const Key('login-email')),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'keeps the submit button as a pill with the label from the design',
          (tester) async {
        await pumpThemed(tester, LoginPage(authService: authService));

        expect(
          find.widgetWithText(FilledButton, 'Iniciar sesión'),
          findsOneWidget,
        );
      },
    );
  });

  group('home screen', () {
    testWidgets(
      'shows the glass app bar with the logout action and a glass card with the greeting',
          (tester) async {
        await pumpThemed(
          tester,
          HomePage(user: buildSession().user, authService: authService),
        );

        expect(find.byType(GlassAppBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(GlassAppBar),
            matching: find.byKey(const Key('home-logout')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(GlassCard),
            matching: find.byKey(const Key('home-greeting')),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('lets the content extend behind the app bar', (tester) async {
      await pumpThemed(
        tester,
        HomePage(user: buildSession().user, authService: authService),
      );

      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold))
            .extendBodyBehindAppBar,
        isTrue,
      );
    });
  });

  group('app shell', () {
    testWidgets('paints the glass background once, above the navigator', (
        tester,) async {
      await tester.pumpWidget(
        CoopSolApp(dependencies: AppDependencies.create()),
      );

      expect(find.byType(GlassBackground), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassBackground),
          matching: find.byType(Navigator),
        ),
        findsOneWidget,
      );
    });

    testWidgets('follows the system brightness', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        CoopSolApp(dependencies: AppDependencies.create()),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode ?? ThemeMode.system, ThemeMode.system);
      expect(
        Theme
            .of(tester.element(find.byType(Navigator)))
            .brightness,
        Brightness.dark,
      );
    });
  });
}
