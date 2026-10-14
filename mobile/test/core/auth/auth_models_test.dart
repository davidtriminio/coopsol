import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final userJson = {
    'id': '6f1c2b0e-4d57-4a8e-9a53-0c1f2f3a4b5c',
    'email': 'socio@example.com',
    'fullName': 'Socio Demo',
    'role': 'Socio',
    'isActive': true,
  };

  group('AuthUser.fromJson', () {
    test('maps every field and converts the role to the enum', () {
      final user = AuthUser.fromJson(userJson);

      expect(user.id, userJson['id']);
      expect(user.email, 'socio@example.com');
      expect(user.fullName, 'Socio Demo');
      expect(user.role, UserRole.socio);
      expect(user.isActive, isTrue);
    });

    test('parses a composite role name', () {
      final user = AuthUser.fromJson({...userJson, 'role': 'OficialCredito'});

      expect(user.role, UserRole.oficialCredito);
    });

    test('throws on an unknown role', () {
      expect(
            () => AuthUser.fromJson({...userJson, 'role': 'Superusuario'}),
        throwsFormatException,
      );
    });
  });

  group('AuthResponse.fromJson', () {
    test('maps tokens, expiry and nested user', () {
      final response = AuthResponse.fromJson({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'expiresInSeconds': 900,
        'user': userJson,
      });

      expect(response.accessToken, 'access-1');
      expect(response.refreshToken, 'refresh-1');
      expect(response.expiresInSeconds, 900);
      expect(response.user.role, UserRole.socio);
    });
  });
}