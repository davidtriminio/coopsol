import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/fake_http.dart';

const refreshPath = '/api/auth/refresh';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore store;
  late FakeAdapter adapter;
  late RefreshCoordinator coordinator;

  void build(FakeHandler handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    coordinator = RefreshCoordinator(AuthApiService(dio), store);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  FakeHandler slowSuccess() {
    return (options) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return jsonResponse(
        authBody(accessToken: 'access-2', refreshToken: 'refresh-2'),
      );
    };
  }

  test('concurrent refreshes share a single request', () async {
    await store.setSession(buildSession());
    build(slowSuccess());

    final results = await Future.wait([
      coordinator.refresh(),
      coordinator.refresh(),
      coordinator.refresh(),
    ]);

    expect(adapter.countOf(refreshPath), 1);
    expect(results.map((r) => r.accessToken), everyElement('access-2'));
    expect(store.accessToken, 'access-2');
    expect(await store.readRefreshToken(), 'refresh-2');
  });

  test('sends the persisted refresh token', () async {
    await store.setSession(buildSession(refreshToken: 'refresh-1'));
    build(slowSuccess());

    await coordinator.refresh();

    expect(adapter.requests.single.data, {'refreshToken': 'refresh-1'});
  });

  test('a later refresh starts a new request once the first completes',
          () async {
        await store.setSession(buildSession());
        build(slowSuccess());

        await coordinator.refresh();
        await coordinator.refresh();

        expect(adapter.countOf(refreshPath), 2);
      });

  test('releases the lock after a rejected refresh and clears the session',
          () async {
        await store.setSession(buildSession());
        build((options) => jsonResponse({'title': 'Unauthorized'}, status: 401));

        await expectLater(coordinator.refresh(), throwsA(isA<DioException>()));

        expect(store.accessToken, isNull);
        expect(await store.readRefreshToken(), isNull);

        await store.setSession(buildSession());
        build(slowSuccess());

        final response = await coordinator.refresh();
        expect(response.accessToken, 'access-2');
      });

  test('keeps the session when the refresh fails without a response',
          () async {
        await store.setSession(buildSession());
        build((options) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        });

        await expectLater(coordinator.refresh(), throwsA(isA<DioException>()));

        expect(store.accessToken, 'access-1');
        expect(await store.readRefreshToken(), 'refresh-1');
      });

  test('throws StateError when there is no refresh token', () async {
    build(slowSuccess());

    await expectLater(coordinator.refresh(), throwsStateError);

    expect(adapter.countOf(refreshPath), 0);
  });
}