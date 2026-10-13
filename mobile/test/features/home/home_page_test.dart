import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:coopsol_mobile/features/home/home_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

void main(){
  late TokenStore store;
  late FakeAdapter adapter;

  Future<void> pumpPage(WidgetTester tester) async {
    adapter = FakeAdapter((options) => ResponseBody.fromString('', 204));
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final authApi = AuthApiService(dio);
    final authService = AuthService(
      authApi,
      store,
      RefreshCoordinator(authApi, store),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          user: buildSession().user,
          authService: authService,
        ),
      ),
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore();
  });

  testWidgets('greets the user and shows the email', (tester) async {
    await pumpPage(tester);

    expect(find.text('Hola, Socio Demo'), findsOneWidget);
    expect(find.text('socio@example.com'), findsOneWidget);
  });

  testWidgets('logout revokes the token and clears the session',
          (tester) async {
        await store.setSession(buildSession());
        await pumpPage(tester);

        await tester.tap(find.byKey(const Key('home-logout')));
        await tester.pump(const Duration(milliseconds: 50));

        expect(adapter.requests.single.uri.path, '/api/auth/logout');
        expect(adapter.requests.single.data, {'refreshToken': 'refresh-1'});
        expect(store.isAuthenticated, isFalse);
        expect(await store.readRefreshToken(), isNull);
      });
}