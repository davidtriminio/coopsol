import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_models.dart';

class TokenStore extends ChangeNotifier {
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
    await _storage.write(key: _refreshTokenKey, value: response.refreshToken);
    _accessToken = response.accessToken;
    _currentUser = response.user;
    notifyListeners();
  }

  void updateUser(AuthUser user){
    _currentUser = user;
    notifyListeners();
  }

  Future<void> clear() async{
    _accessToken = null;
    _currentUser = null;
    try{
      await _storage.delete(key: _refreshTokenKey);
    } finally {
      notifyListeners();
    }
  }

  bool hasRole(List<UserRole> roles){
    final user = _currentUser;
    return user != null && roles.contains(user.role);
  }

}