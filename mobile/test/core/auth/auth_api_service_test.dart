import 'dart:convert';
import 'dart:typed_data';

import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef FakeHandler = ResponseBody Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
      ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

const userJson = {
  'id': '6f1c2b0e-4d57-4a8e-9a53-0c1f2f3a4b5c',
  'email': 'socio@example.com',
  'fullName': 'Socio Demo',
  'role': 'Socio',
  'isActive': true,
};

const authJson = {
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
  'expiresInSeconds': 900,
  'user': userJson,
};

void main() {
  late FakeAdapter adapter;
  late AuthApiService service;

  AuthApiService buildService(FakeHandler handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    return AuthApiService(dio);
  }

  test('login posts credentials and parses the auth response', () async {
    service = buildService((_) => jsonResponse(authJson));

    final response = await service.login(
      email: 'socio@example.com',
      password: 'secret',
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), 'http://api.test/api/auth/login');
    expect(request.data, {'email': 'socio@example.com', 'password': 'secret'});
    expect(response.accessToken, 'access-1');
    expect(response.refreshToken, 'refresh-1');
    expect(response.user.role, UserRole.socio);
  });

  test('refresh posts the refresh token and parses the new session', () async {
    service = buildService(
          (_) => jsonResponse({...authJson, 'accessToken': 'access-2'}),
    );

    final response = await service.refresh('refresh-1');

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/auth/refresh');
    expect(request.data, {'refreshToken': 'refresh-1'});
    expect(response.accessToken, 'access-2');
  });

  test('logout posts the refresh token', () async {
    service = buildService((_) => ResponseBody.fromString('', 204));

    await service.logout('refresh-1');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/auth/logout');
    expect(request.data, {'refreshToken': 'refresh-1'});
  });

  test('me gets the current user', () async {
    service = buildService((_) => jsonResponse(userJson));

    final user = await service.me();

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/api/auth/me');
    expect(user.email, 'socio@example.com');
    expect(user.role, UserRole.socio);
  });

  test('login surfaces a 401 as a DioException with the status code', () async {
    service = buildService(
          (_) => jsonResponse({'title': 'Unauthorized'}, status: 401),
    );

    await expectLater(
      service.login(email: 'socio@example.com', password: 'wrong'),
      throwsA(
        isA<DioException>().having(
              (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}