import 'package:dio/dio.dart';
import '../config/app_config.dart';

Dio buildApiClient(){
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json'
    )
  );
}