import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:dio/dio.dart';

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions options);
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

  int countOf(String path) {
    return requests.where((request) => request.uri.path == path).length;
  }
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

Map<String, dynamic> authBody({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) {
  return {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': 900,
    'user': {
      'id': '6f1c2b0e-4d57-4a8e-9a53-0c1f2f3a4b5c',
      'email': 'socio@example.com',
      'fullName': 'Socio Demo',
      'role': 'Socio',
      'isActive': true,
    },
  };
}

AuthResponse buildSession({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) {
  return AuthResponse.fromJson(
    authBody(accessToken: accessToken, refreshToken: refreshToken),
  );
}