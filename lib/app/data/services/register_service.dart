import 'package:dio/dio.dart';
import 'api_service.dart';

class RegisterService {
  static Future<Response> registerUser(
      String username, String email, String password) async {
    return await ApiService.dioClient.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
  }
}
