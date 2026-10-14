import 'package:dio/dio.dart';
import 'auth_models.dart';

class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;
  Future<AuthResponse> login({
    required String email,
    required String password
}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
    data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthResponse> refresh(String refreshToken) async{
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken}
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken}
    );
  }

  Future<AuthUser> me() async{
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    return AuthUser.fromJson(response.data!);
  }
}