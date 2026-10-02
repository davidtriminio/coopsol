import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  String? _accessToken;
  AuthUser? _currentUser;

  String? get accessToken => _accessToken;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;

  Future<String?> readRefreshToken(){
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> setSession(AuthResponse response) async{
    _accessToken = response.accessToken;
    _currentUser = response.user;
    await _storage.write(key: _refreshTokenKey, value: response.refreshToken);
  }

  void updateUser(AuthUser user){
    _currentUser = user;
  }

  Future<void> clear() async{
    _accessToken = null;
    _currentUser = null;
    await _storage.delete(key: _refreshTokenKey);
  }

  bool hasRole(List<UserRole> roles){
    final user = _currentUser;
    return user != null && roles.contains(user.role);
  }

}