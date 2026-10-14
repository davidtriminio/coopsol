import 'package:coopsol_mobile/core/auth/auth_api_service.dart';
import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart';

class RefreshCoordinator {
  RefreshCoordinator(this._authApi, this._tokenStore);

  final AuthApiService _authApi;
  final TokenStore _tokenStore;

  Future<AuthResponse>? _inFlight;

  Future<AuthResponse> refresh(){
    final pending = _inFlight;
    if(pending != null){
      return pending;
    }

    final future = _performRefresh().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<AuthResponse> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if(refreshToken == null){
      await _tokenStore.clear();
      throw StateError('No refresh token available');
    }

    try{
      final response = await _authApi.refresh(refreshToken);
      await _tokenStore.setSession(response);
      return response;
    } on DioException catch (error) {
      if(error.response != null){
        await _tokenStore.clear();
      }
      rethrow;
    }
  }
}