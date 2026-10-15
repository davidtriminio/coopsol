import 'package:coopsol_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

String resolve({
  String defined = '',
  bool isRelease = false,
  bool isAndroid = false,
}) {
  return AppConfig.resolveApiUrl(
    defined: defined,
    isRelease: isRelease,
    isAndroid: isAndroid,
  );
}

void main() {
  group('AppConfig.resolveApiUrl in debug', () {
    test('uses the emulator host on Android when API_URL is empty', () {
      expect(resolve(isAndroid: true), 'http://10.0.2.2:5143');
    });

    test('uses localhost on other platforms when API_URL is empty', () {
      expect(resolve(), 'http://localhost:5143');
    });

    test('prefers the defined API_URL over the platform default', () {
      expect(
        resolve(defined: 'http://192.168.1.50:5143', isAndroid: true),
        'http://192.168.1.50:5143',
      );
    });

    test('treats a blank API_URL as missing', () {
      expect(resolve(defined: '   ', isAndroid: true), 'http://10.0.2.2:5143');
    });
  });

  group('AppConfig.resolveApiUrl in release', () {
    test('returns the defined https URL', () {
      expect(
        resolve(defined: 'https://api.example.com', isRelease: true),
        'https://api.example.com',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        resolve(defined: '  https://api.example.com  ', isRelease: true),
        'https://api.example.com',
      );
    });

    test('throws when API_URL is missing', () {
      expect(
        () => resolve(isRelease: true, isAndroid: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when API_URL is blank', () {
      expect(
        () => resolve(defined: '   ', isRelease: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when API_URL uses plain http', () {
      expect(
        () => resolve(defined: 'http://api.example.com', isRelease: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when API_URL is not an absolute URL', () {
      expect(
        () => resolve(defined: 'api.example.com', isRelease: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when API_URL has no host', () {
      expect(
        () => resolve(defined: 'https://', isRelease: true),
        throwsA(isA<StateError>()),
      );
    });
  });
}
