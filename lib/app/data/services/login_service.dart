import 'package:dio/dio.dart';
import 'api_service.dart';

class LoginService {
  static Future<Response> loginUser(String email, String password) async {
    return await ApiService.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }
}
