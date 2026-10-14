import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/session_controller.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore store;
  late SessionController controller;

  void build(FakeHandler handler) {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeAdapter(handler);
    final authApi = AuthApiService(dio);
    final authService = AuthService(
      authApi,
      store,
      RefreshCoordinator(authApi, store),
    );
    controller = SessionController(authService, store);
  }

  ResponseBody refreshed() {
    return jsonResponse(
      authBody(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );
  }

  void seedRefreshToken() {
    FlutterSecureStorage.setMockInitialValues({'refresh_token': 'refresh-1'});
    store = TokenStore();
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  test('is restoring until restore completes', () {
    build((options) => refreshed());

    expect(controller.status, SessionStatus.restoring);
  });

  test('is unauthenticated after restoring without a stored token', () async {
    build((options) => refreshed());

    await controller.restore();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.currentUser, isNull);
  });

  test('is authenticated after restoring with a valid token', () async {
    seedRefreshToken();
    build((options) => refreshed());

    await controller.restore();

    expect(controller.status, SessionStatus.authenticated);
    expect(controller.currentUser?.email, 'socio@example.com');
  });

  test('is unauthenticated when the stored token is rejected', () async {
    seedRefreshToken();
    build((options) => jsonResponse({'title': 'Unauthorized'}, status: 401));

    await controller.restore();

    expect(controller.status, SessionStatus.unauthenticated);
  });

  test('leaves restoring even when the server is unreachable', () async {
    seedRefreshToken();
    build((options) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    });

    await controller.restore();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(await store.readRefreshToken(), 'refresh-1');
  });

  test('notifies when the restoration finishes', () async {
    build((options) => refreshed());
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.restore();

    expect(notifications, 1);
  });

  test('becomes authenticated when the store receives a session', () async {
    build((options) => refreshed());
    await controller.restore();
    final seen = <SessionStatus>[];
    controller.addListener(() => seen.add(controller.status));

    await store.setSession(buildSession());

    expect(seen, [SessionStatus.authenticated]);
    expect(controller.currentUser?.email, 'socio@example.com');
  });

  test('becomes unauthenticated when the store loses the session', () async {
    seedRefreshToken();
    build((options) => refreshed());
    await controller.restore();
    final seen = <SessionStatus>[];
    controller.addListener(() => seen.add(controller.status));

    await store.clear();

    expect(seen, [SessionStatus.unauthenticated]);
  });

  test('stops following the store after dispose', () async {
    build((options) => refreshed());
    controller.dispose();

    await store.setSession(buildSession());
    await store.clear();
  });
}