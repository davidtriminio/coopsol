import 'package:coopsol_mobile/core/auth/auth_models.dart';

class RoleNotAllowedException implements Exception{
  const RoleNotAllowedException(this.role);
  final UserRole role;

  @override
  String toString() => 'RoleNotAllowedException: ${role.value}';
}