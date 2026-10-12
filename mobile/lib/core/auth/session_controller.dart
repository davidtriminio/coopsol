import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:flutter/cupertino.dart';

import 'auth_models.dart';

enum SessionStatus {restoring, authenticated, unauthenticated}

class SessionController extends ChangeNotifier{
  SessionController(this._authService, this._tokenStore){
    _tokenStore.addListener(notifyListeners);
  }

  final AuthService _authService;
  final TokenStore _tokenStore;

  bool _restored = false;

  SessionStatus get status {
    if(!_restored){
      return SessionStatus.restoring;
    }
    return _tokenStore.isAuthenticated
        ? SessionStatus.authenticated
        : SessionStatus.unauthenticated;
  }

  AuthUser? get currentUser => _tokenStore.currentUser;

  Future <void> restore() async{
    try{
      await _authService.restoreSession();
    } finally{
      _restored = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokenStore.removeListener(notifyListeners);
    super.dispose();
  }

}