import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStore,
    required this._refreshCoordinator,
    required this._dio,
  });

  static const List<String> _refreshExemptPaths = [
    '/api/auth/login',
    '/api/auth/refresh',
  ];
  static const String _retriedKey = 'authRetried';

  final TokenStore _tokenStore;
  final RefreshCoordinator _refreshCoordinator;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = _tokenStore.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isExempt = _refreshExemptPaths.any(request.path.contains);
    final alreadyRetried = request.extra[_retriedKey] == true;

    if (!isUnauthorized || isExempt || alreadyRetried) {
      handler.next(err);
      return;
    }
    try {
      await _refreshCoordinator.refresh();
      request.extra[_retriedKey] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.reject(error);
    } catch (_) {
      handler.next(err);
    }
  }
}
