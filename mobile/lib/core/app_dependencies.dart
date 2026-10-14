import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_interceptor.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/session_controller.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:coopsol_mobile/core/http/api_client.dart';
import 'package:dio/dio.dart';

class AppDependencies {
  AppDependencies._({
    required this.apiDio,
    required this.tokenStore,
    required this.authService,
    required this.sessionController
  });

  final Dio apiDio;
  final TokenStore tokenStore;
  final AuthService authService;
  final SessionController sessionController;

  factory AppDependencies.create() {
    final tokenStore = TokenStore();

    final refreshDio = buildApiClient();
    final refreshCoordinator = RefreshCoordinator(
      AuthApiService(refreshDio),
      tokenStore,
    );

    final apiDio = buildApiClient();
    apiDio.interceptors.add(
      AuthInterceptor(
        tokenStore: tokenStore,
        refreshCoordinator: refreshCoordinator,
        dio: apiDio,
      ),
    );

    final authService = AuthService(
      AuthApiService(apiDio),
      tokenStore,
      refreshCoordinator,
    );

    return AppDependencies._(
      apiDio: apiDio,
      tokenStore: tokenStore,
      authService: authService,
      sessionController: SessionController(authService, tokenStore)
    );
  }
}
