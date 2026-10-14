import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_interceptor.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

const baseUrl = 'http://api.test';
const refreshPath = '/api/auth/refresh';
const dataPath = '/api/data';

FakeHandler server({String validToken = 'access-2'}) {
  return (options) async {
    if (options.uri.path == refreshPath) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return jsonResponse(
        authBody(accessToken: 'access-2', refreshToken: 'refresh-2'),
      );
    }
    if (options.headers['Authorization'] == 'Bearer $validToken') {
      return jsonResponse({'ok': true});
    }
    return jsonResponse({'title': 'Unauthorized'}, status: 401);
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore store;
  late FakeAdapter adapter;
  late Dio apiDio;

  void build(FakeHandler handler) {
    adapter = FakeAdapter(handler);
    final refreshDio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    final coordinator = RefreshCoordinator(AuthApiService(refreshDio), store);
    apiDio = Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
    apiDio.interceptors.add(
      AuthInterceptor(
        tokenStore: store,
        refreshCoordinator: coordinator,
        dio: apiDio,
      ),
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  test('attaches the bearer token when there is a session', () async {
    await store.setSession(buildSession());
    build(server(validToken: 'access-1'));

    final response = await apiDio.get<Map<String, dynamic>>(dataPath);

    expect(response.statusCode, 200);
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('sends no authorization header without a session', () async {
    build(server());

    await expectLater(
      apiDio.get<Map<String, dynamic>>(dataPath),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests.first.headers['Authorization'], isNull);
  });

  test('refreshes on 401 and retries the request with the new token',
          () async {
        await store.setSession(buildSession());
        build(server());

        final response = await apiDio.get<Map<String, dynamic>>(dataPath);

        expect(response.statusCode, 200);
        expect(response.data, {'ok': true});
        expect(
          adapter.requests.map((r) => r.uri.path).toList(),
          [dataPath, refreshPath, dataPath],
        );
        expect(adapter.requests.last.headers['Authorization'], 'Bearer access-2');
        expect(store.accessToken, 'access-2');
        expect(await store.readRefreshToken(), 'refresh-2');
      });

  test('concurrent 401s trigger a single refresh', () async {
    await store.setSession(buildSession());
    build(server());

    final responses = await Future.wait([
      apiDio.get<Map<String, dynamic>>(dataPath),
      apiDio.get<Map<String, dynamic>>(dataPath),
      apiDio.get<Map<String, dynamic>>(dataPath),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(adapter.countOf(refreshPath), 1);
  });

  test('retries only once when the request keeps returning 401', () async {
    await store.setSession(buildSession());
    build(server(validToken: 'never'));

    await expectLater(
      apiDio.get<Map<String, dynamic>>(dataPath),
      throwsA(
        isA<DioException>().having(
              (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(adapter.countOf(dataPath), 2);
    expect(adapter.countOf(refreshPath), 1);
  });

  test('does not refresh when login itself returns 401', () async {
    build(server());

    await expectLater(
      apiDio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': 'socio@example.com', 'password': 'wrong'},
      ),
      throwsA(isA<DioException>()),
    );

    expect(adapter.countOf(refreshPath), 0);
  });

  test('surfaces the failure and clears the session when refresh is rejected',
          () async {
        await store.setSession(buildSession());
        build((options) => jsonResponse({'title': 'Unauthorized'}, status: 401));

        await expectLater(
          apiDio.get<Map<String, dynamic>>(dataPath),
          throwsA(isA<DioException>()),
        );

        expect(store.accessToken, isNull);
        expect(await store.readRefreshToken(), isNull);
      });

  test('keeps the session when the refresh cannot reach the server', () async {
    await store.setSession(buildSession());
    build((options) {
      if (options.uri.path == refreshPath) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return jsonResponse({'title': 'Unauthorized'}, status: 401);
    });

    await expectLater(
      apiDio.get<Map<String, dynamic>>(dataPath),
      throwsA(isA<DioException>()),
    );

    expect(await store.readRefreshToken(), 'refresh-1');
  });

  test('returns the original 401 when there is no refresh token', () async {
    build(server());

    await expectLater(
      apiDio.get<Map<String, dynamic>>(dataPath),
      throwsA(
        isA<DioException>().having(
              (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(adapter.countOf(refreshPath), 0);
  });
}