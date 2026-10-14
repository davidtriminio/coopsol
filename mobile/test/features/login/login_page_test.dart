import 'dart:async';

import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_exceptions.dart';
import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:coopsol_mobile/features/login/login_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

const emailField = Key('login-email');
const passwordField = Key('login-password');
const submitButton = Key('login-submit');
const errorText = Key('login-error');

void main() {
  late TokenStore store;
  late FakeAdapter adapter;

  Future<void> pumpPage(WidgetTester tester, FakeHandler handler) async {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final authApi = AuthApiService(dio);
    final authService = AuthService(
      authApi,
      store,
      RefreshCoordinator(authApi, store),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authService: authService)),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> fillAndSubmit(
      WidgetTester tester, {
        String email = 'socio@example.com',
        String password = 'secret',
      }) async {
    await tester.enterText(find.byKey(emailField), email);
    await tester.enterText(find.byKey(passwordField), password);
    await tester.tap(find.byKey(submitButton));
    await settle(tester);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  group('describeLoginError', () {
    DioException responseError(int status, [Object? data]) {
      final options = RequestOptions(path: '/api/auth/login');
      return DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: status,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    test('uses the server title on a 401', () {
      final error = responseError(401, {'title': 'Credenciales incorrectas'});

      expect(describeLoginError(error), 'Credenciales incorrectas');
    });

    test('falls back to a default message on a 401 without title', () {
      expect(describeLoginError(responseError(401)), 'Credenciales inválidas');
    });

    test('explains the rate limit on a 429', () {
      expect(
        describeLoginError(responseError(429)),
        'Demasiados intentos. Espera un minuto e intenta de nuevo.',
      );
    });

    test('explains that the app is for socios on a rejected role', () {
      expect(
        describeLoginError(const RoleNotAllowedException(UserRole.cajero)),
        'Esta aplicación es solo para socios. El personal debe usar el sistema web.',
      );
    });

    test('uses a generic message for any other failure', () {
      expect(
        describeLoginError(responseError(500)),
        'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
      expect(
        describeLoginError(StateError('boom')),
        'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    });
  });

  group('LoginPage', () {
    testWidgets('shows the form with an enabled submit button', (tester) async {
      await pumpPage(tester, (options) => jsonResponse(authBody()));

      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.byKey(emailField), findsOneWidget);
      expect(find.byKey(passwordField), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byKey(errorText), findsNothing);
    });

    testWidgets('validates empty fields without calling the server',
            (tester) async {
          await pumpPage(tester, (options) => jsonResponse(authBody()));

          await tester.tap(find.byKey(submitButton));
          await tester.pump();

          expect(find.text('Ingresa un correo válido'), findsOneWidget);
          expect(find.text('La contraseña es obligatoria'), findsOneWidget);
          expect(adapter.requests, isEmpty);
        });

    testWidgets('rejects a malformed email', (tester) async {
      await pumpPage(tester, (options) => jsonResponse(authBody()));

      await fillAndSubmit(tester, email: 'not-an-email');

      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('sends the trimmed email and the password as typed',
            (tester) async {
          await pumpPage(tester, (options) => jsonResponse(authBody()));

          await fillAndSubmit(
            tester,
            email: '  socio@example.com  ',
            password: ' secret ',
          );
          await tester.pump();

          expect(adapter.requests.single.data, {
            'email': 'socio@example.com',
            'password': ' secret ',
          });
          expect(store.isAuthenticated, isTrue);
          expect(find.byKey(errorText), findsNothing);
        });

    testWidgets('shows the server message when the credentials are rejected',
            (tester) async {
          await pumpPage(
            tester,
                (options) => jsonResponse(
              {'title': 'Correo o contraseña incorrectos'},
              status: 401,
            ),
          );

          await fillAndSubmit(tester);
          await tester.pump();

          expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
          expect(store.isAuthenticated, isFalse);
        });

    testWidgets('shows the role message when a staff account logs in',
            (tester) async {
          await pumpPage(tester, (options) {
            if (options.uri.path == '/api/auth/login') {
              final body = authBody();
              (body['user'] as Map<String, dynamic>)['role'] = 'Cajero';
              return jsonResponse(body);
            }
            return ResponseBody.fromString('', 204);
          });

          await fillAndSubmit(tester);
          await tester.pump();

          expect(
            find.text(
              'Esta aplicación es solo para socios. El personal debe usar el sistema web.',
            ),
            findsOneWidget,
          );
          expect(store.isAuthenticated, isFalse);
        });

    testWidgets('disables the button and ignores a second submit while loading',
            (tester) async {
          final completer = Completer<ResponseBody>();
          await pumpPage(tester, (options) => completer.future);

          await fillAndSubmit(tester);

          final button = tester.widget<FilledButton>(find.byKey(submitButton));
          expect(button.onPressed, isNull);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          await tester.tap(find.byKey(submitButton), warnIfMissed: false);
          await tester.pump();
          expect(adapter.requests, hasLength(1));

          completer.complete(jsonResponse(authBody()));
          await settle(tester);

          expect(find.byType(CircularProgressIndicator), findsNothing);
        });

    testWidgets('clears the previous error when submitting again',
            (tester) async {
          var attempt = 0;
          await pumpPage(tester, (options) {
            attempt++;
            if (attempt == 1) {
              return jsonResponse({'title': 'Mensaje de error'}, status: 401);
            }
            return jsonResponse(authBody());
          });

          await fillAndSubmit(tester);
          await tester.pump();
          expect(find.text('Mensaje de error'), findsOneWidget);

          await tester.tap(find.byKey(submitButton));
          await settle(tester);

          expect(find.text('Mensaje de error'), findsNothing);
        });
  });
}