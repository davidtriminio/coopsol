import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

AuthResponse buildResponse({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  UserRole role = UserRole.socio,
}) {
  return AuthResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresInSeconds: 900,
    user: AuthUser(
      id: '6f1c2b0e-4d57-4a8e-9a53-0c1f2f3a4b5c',
      email: 'socio@example.com',
      fullName: 'Socio Demo',
      role: role,
      isActive: true,
    ),
  );
}

class FailingStorage extends FlutterSecureStorage {
  FailingStorage({this.failOnWrite = false, this.failOnDelete = false});

  final bool failOnWrite;
  final bool failOnDelete;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (failOnWrite) {
      throw StateError('storage unavailable');
    }
    return super.write(key: key, value: value);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (failOnDelete) {
      throw StateError('storage unavailable');
    }
    return super.delete(key: key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('starts unauthenticated with no refresh token', () async {
    final store = TokenStore();

    expect(store.isAuthenticated, isFalse);
    expect(store.accessToken, isNull);
    expect(store.currentUser, isNull);
    expect(await store.readRefreshToken(), isNull);
  });

  test(
    'setSession keeps the session in memory and persists the refresh token',
    () async {
      final store = TokenStore();

      await store.setSession(buildResponse());

      expect(store.isAuthenticated, isTrue);
      expect(store.accessToken, 'access-1');
      expect(store.currentUser?.email, 'socio@example.com');
      expect(await store.readRefreshToken(), 'refresh-1');
    },
  );

  test('a new store instance recovers only the refresh token', () async {
    await TokenStore().setSession(buildResponse());

    final restarted = TokenStore();

    expect(restarted.isAuthenticated, isFalse);
    expect(restarted.accessToken, isNull);
    expect(await restarted.readRefreshToken(), 'refresh-1');
  });

  test('setSession overwrites the refresh token on rotation', () async {
    final store = TokenStore();

    await store.setSession(buildResponse());
    await store.setSession(
      buildResponse(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );

    expect(store.accessToken, 'access-2');
    expect(await store.readRefreshToken(), 'refresh-2');
  });

  test('clear wipes memory and the persisted refresh token', () async {
    final store = TokenStore();
    await store.setSession(buildResponse());

    await store.clear();

    expect(store.isAuthenticated, isFalse);
    expect(store.currentUser, isNull);
    expect(await store.readRefreshToken(), isNull);
    expect(await TokenStore().readRefreshToken(), isNull);
  });

  test('updateUser replaces the user without touching the tokens', () async {
    final store = TokenStore();
    await store.setSession(buildResponse());

    store.updateUser(buildResponse(role: UserRole.gerente).user);

    expect(store.currentUser?.role, UserRole.gerente);
    expect(store.accessToken, 'access-1');
    expect(await store.readRefreshToken(), 'refresh-1');
  });

  group('hasRole', () {
    test('is false when there is no session', () {
      expect(TokenStore().hasRole([UserRole.socio]), isFalse);
    });

    test('matches any of the given roles', () async {
      final store = TokenStore();
      await store.setSession(buildResponse(role: UserRole.cajero));

      expect(store.hasRole([UserRole.cajero, UserRole.admin]), isTrue);
    });

    test('is false when the role is not in the list', () async {
      final store = TokenStore();
      await store.setSession(buildResponse(role: UserRole.socio));

      expect(store.hasRole([UserRole.gerente, UserRole.admin]), isFalse);
    });
  });

  group('notifications', () {
    test('setSession notifies once with the session already set', () async {
      final store = TokenStore();
      final seen = <String?>[];
      store.addListener(() => seen.add(store.accessToken));

      await store.setSession(buildResponse());

      expect(seen, ['access-1']);
    });

    test('updateUser notifies once with the new user', () async {
      final store = TokenStore();
      await store.setSession(buildResponse());
      final seen = <UserRole?>[];
      store.addListener(() => seen.add(store.currentUser?.role));

      store.updateUser(buildResponse(role: UserRole.gerente).user);

      expect(seen, [UserRole.gerente]);
    });

    test('clear notifies once with the session already empty', () async {
      final store = TokenStore();
      await store.setSession(buildResponse());
      final seen = <bool>[];
      store.addListener(() => seen.add(store.isAuthenticated));

      await store.clear();

      expect(seen, [false]);
    });

    test('setSession leaves no partial session when storage fails', () async {
      final store = TokenStore(storage: FailingStorage(failOnWrite: true));
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.setSession(buildResponse()),
        throwsStateError,
      );

      expect(store.isAuthenticated, isFalse);
      expect(store.currentUser, isNull);
      expect(notifications, 0);
    });

    test('clear empties memory and notifies even when storage fails',
            () async {
          final store = TokenStore(storage: FailingStorage(failOnDelete: true));
          await store.setSession(buildResponse());
          var notifications = 0;
          store.addListener(() => notifications++);

          await expectLater(store.clear(), throwsStateError);

          expect(store.isAuthenticated, isFalse);
          expect(store.currentUser, isNull);
          expect(notifications, 1);
        });
  });
}
