import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_exceptions.dart';
import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

const loginPath = '/api/auth/login';
const refreshPath = '/api/auth/refresh';
const logoutPath = '/api/auth/logout';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore store;
  late FakeAdapter adapter;
  late AuthService service;

  void build(FakeHandler handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final authApi = AuthApiService(dio);
    service = AuthService(authApi, store, RefreshCoordinator(authApi, store));
  }

  ResponseBody unauthorized() {
    return jsonResponse({'title': 'Unauthorized'}, status: 401);
  }

  ResponseBody loginAs(String role) {
    final body = authBody();
    (body['user'] as Map<String, dynamic>)['role'] = role;
    return jsonResponse(body);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  group('login', () {
    test('stores the session and returns the user', () async {
      build((options) => jsonResponse(authBody()));

      final user = await service.login(
        email: 'socio@example.com',
        password: 'secret',
      );

      expect(user.email, 'socio@example.com');
      expect(user.role, UserRole.socio);
      expect(store.isAuthenticated, isTrue);
      expect(store.accessToken, 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
      expect(adapter.requests.single.data, {
        'email': 'socio@example.com',
        'password': 'secret',
      });
    });

    test('leaves the store empty when the credentials are rejected', () async {
      build((options) => unauthorized());

      await expectLater(
        service.login(email: 'socio@example.com', password: 'wrong'),
        throwsA(isA<DioException>()),
      );

      expect(store.isAuthenticated, isFalse);
      expect(await store.readRefreshToken(), isNull);
    });

    for (final role in ['Cajero', 'OficialCredito', 'Gerente', 'Admin']) {
      test('rejects the $role role without storing a session', () async {
        build((options) {
          if (options.uri.path == loginPath) {
            return loginAs(role);
          }
          return ResponseBody.fromString('', 204);
        });
        var notifications = 0;
        store.addListener(() => notifications++);

        await expectLater(
          service.login(email: 'staff@example.com', password: 'secret'),
          throwsA(isA<RoleNotAllowedException>()),
        );

        expect(store.isAuthenticated, isFalse);
        expect(await store.readRefreshToken(), isNull);
        expect(notifications, 0);
      });
    }

    test('revokes the refresh token issued to a rejected role', () async {
      build((options) {
        if (options.uri.path == loginPath) {
          return loginAs('Cajero');
        }
        return ResponseBody.fromString('', 204);
      });

      await expectLater(
        service.login(email: 'staff@example.com', password: 'secret'),
        throwsA(isA<RoleNotAllowedException>()),
      );

      final logout = adapter.requests.last;
      expect(logout.uri.path, logoutPath);
      expect(logout.data, {'refreshToken': 'refresh-1'});
    });

    test('still rejects the role when the revocation fails', () async {
      build((options) {
        if (options.uri.path == loginPath) {
          return loginAs('Admin');
        }
        return jsonResponse({'title': 'Error'}, status: 500);
      });

      await expectLater(
        service.login(email: 'staff@example.com', password: 'secret'),
        throwsA(isA<RoleNotAllowedException>()),
      );

      expect(store.isAuthenticated, isFalse);
    });
  });

  group('restoreSession', () {
    test(
      'returns false without calling the server when there is no token',
      () async {
        build((options) => jsonResponse(authBody()));

        final restored = await service.restoreSession();

        expect(restored, isFalse);
        expect(adapter.requests, isEmpty);
      },
    );

    test('refreshes with the stored token and starts a session', () async {
      FlutterSecureStorage.setMockInitialValues({'refresh_token': 'refresh-1'});
      store = TokenStore();
      build(
        (options) => jsonResponse(
          authBody(accessToken: 'access-2', refreshToken: 'refresh-2'),
        ),
      );

      final restored = await service.restoreSession();

      expect(restored, isTrue);
      expect(adapter.requests.single.data, {'refreshToken': 'refresh-1'});
      expect(store.accessToken, 'access-2');
      expect(store.currentUser?.email, 'socio@example.com');
      expect(await store.readRefreshToken(), 'refresh-2');
    });

    test(
      'returns false and clears the session when the token is rejected',
      () async {
        FlutterSecureStorage.setMockInitialValues({'refresh_token': 'stale'});
        store = TokenStore();
        build((options) => unauthorized());

        final restored = await service.restoreSession();

        expect(restored, isFalse);
        expect(store.isAuthenticated, isFalse);
        expect(await store.readRefreshToken(), isNull);
      },
    );

    test(
      'returns false but keeps the token when the server is unreachable',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'refresh_token': 'refresh-1',
        });
        store = TokenStore();
        build((options) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        });

        final restored = await service.restoreSession();

        expect(restored, isFalse);
        expect(await store.readRefreshToken(), 'refresh-1');
      },
    );
  });

  group('logout', () {
    test('revokes the refresh token and clears the session', () async {
      await store.setSession(buildSession());
      build((options) => ResponseBody.fromString('', 204));

      await service.logout();

      expect(adapter.requests.single.uri.path, logoutPath);
      expect(adapter.requests.single.data, {'refreshToken': 'refresh-1'});
      expect(store.isAuthenticated, isFalse);
      expect(await store.readRefreshToken(), isNull);
    });

    test('clears the session even when the server call fails', () async {
      await store.setSession(buildSession());
      build((options) => jsonResponse({'title': 'Error'}, status: 500));

      await service.logout();

      expect(store.isAuthenticated, isFalse);
      expect(await store.readRefreshToken(), isNull);
    });

    test(
      'clears the session without a request when there is no token',
      () async {
        build((options) => ResponseBody.fromString('', 204));

        await service.logout();

        expect(adapter.requests, isEmpty);
        expect(store.isAuthenticated, isFalse);
      },
    );
  });
}
