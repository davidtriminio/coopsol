import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/session_controller.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:coopsol_mobile/features/home/home_page.dart';
import 'package:coopsol_mobile/features/login/login_page.dart';
import 'package:coopsol_mobile/features/session/session_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

const loginPath = '/api/auth/login';
const refreshPath = '/api/auth/refresh';
const logoutPath = '/api/auth/logout';

void main() {
  late TokenStore store;
  late SessionController controller;

  FakeHandler server({bool refreshAccepted = true}) {
    return (options) {
      switch (options.uri.path) {
        case loginPath:
          return jsonResponse(authBody());
        case refreshPath:
          if (refreshAccepted) {
            return jsonResponse(
              authBody(accessToken: 'access-2', refreshToken: 'refresh-2'),
            );
          }
          return jsonResponse({'title': 'Unauthorized'}, status: 401);
        default:
          return ResponseBody.fromString('', 204);
      }
    };
  }

  Future<void> pumpGate(WidgetTester tester, FakeHandler handler) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeAdapter(handler);
    final authApi = AuthApiService(dio);
    final authService = AuthService(
      authApi,
      store,
      RefreshCoordinator(authApi, store),
    );
    controller = SessionController(authService, store);

    await tester.pumpWidget(
      MaterialApp(
        home: SessionGate(
          sessionController: controller,
          authService: authService,
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
  }

  void seedRefreshToken() {
    FlutterSecureStorage.setMockInitialValues({'refresh_token': 'refresh-1'});
    store = TokenStore();
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  testWidgets('shows the loading indicator while the session is restored', (
    tester,
  ) async {
    await pumpGate(tester, server());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('shows the login page when there is no stored session', (
    tester,
  ) async {
    await pumpGate(tester, server());

    controller.restore();
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('shows the home page when the stored token is accepted', (
    tester,
  ) async {
    seedRefreshToken();
    await pumpGate(tester, server());

    controller.restore();
    await settle(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Hola, Socio Demo'), findsOneWidget);
  });

  testWidgets('shows the login page when the stored token is rejected', (
    tester,
  ) async {
    seedRefreshToken();
    await pumpGate(tester, server(refreshAccepted: false));

    controller.restore();
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('moves from login to home after a successful login', (
    tester,
  ) async {
    await pumpGate(tester, server());
    controller.restore();
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'socio@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'secret');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('returns to login after logout', (tester) async {
    seedRefreshToken();
    await pumpGate(tester, server());
    controller.restore();
    await settle(tester);
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-logout')));
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('returns to login when the session is lost while in use', (
    tester,
  ) async {
    seedRefreshToken();
    await pumpGate(tester, server());
    controller.restore();
    await settle(tester);
    expect(find.byType(HomePage), findsOneWidget);

    await store.clear();
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });
}
