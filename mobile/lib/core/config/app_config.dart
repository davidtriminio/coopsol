import 'dart:io';

class AppConfig {
  AppConfig._();

  static const String _defineApiUrl = String.fromEnvironment('API_URL');

  static String get apiUrl{
    if (_defineApiUrl.isNotEmpty) return _defineApiUrl;
    return Platform.isAndroid ? 'http://10.0.2.2:5143' : 'http://localhost:5143';
  }
}