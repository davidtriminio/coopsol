import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _defineApiUrl = String.fromEnvironment('API_URL');

  static String get apiUrl => resolveApiUrl(
    defined: _defineApiUrl,
    isRelease: kReleaseMode,
    isAndroid: Platform.isAndroid,
  );

  static String resolveApiUrl({
    required String defined,
    required bool isRelease,
    required bool isAndroid,
  }) {
    final value = defined.trim();

    if (isRelease) {
      if (value.isEmpty) {
        throw StateError(
          'API_URL es obligatoria en builds release.'
          'Comila con --dart-define=API_UR=https://tu-api',
        );
      }

      final uri = Uri.tryParse(value);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw StateError(
          'API_URL debe ser una URL https absoluta en builds release.',
        );
      }
      return value;
    }

    if (value.isNotEmpty) {
      return value;
    }
    return isAndroid ? 'http://10.0.2.2:5143' : 'http://localhost:5143';
  }
}
