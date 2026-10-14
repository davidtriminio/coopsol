import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_exceptions.dart';
import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/refresh_coordinator.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';

class AuthService {
  AuthService(this._authApi, this._tokenStore, this._refreshCoordinator);

  static const UserRole _allowedRole = UserRole.socio;

  final AuthApiService _authApi;
  final TokenStore _tokenStore;
  final RefreshCoordinator _refreshCoordinator;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.login(email: email, password: password);

    if(response.user.role != _allowedRole){
      await _revokeQuietly(response.refreshToken);
      throw RoleNotAllowedException(response.user.role);
    }

    await _tokenStore.setSession(response);
    return response.user;
  }

  Future<bool> restoreSession() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) {
      return false;
    }

    try {
      await _refreshCoordinator.refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _revokeQuietly(refreshToken);
      }
    }finally {
      await _tokenStore.clear();
    }
  }

  Future<void> _revokeQuietly(String refreshToken) async{
    try{
      await _authApi.logout(refreshToken);
    } on DioException{
      return;
    }
  }
}
