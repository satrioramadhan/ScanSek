import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/history_item.dart';

class GulaService {
  /// POST /gula
  static Future<Response> tambahGula(HistoryItem item) async {
    final token = await _getToken();
    return await ApiService.dio.post(
      '/api/gula',
      data: item.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// GET /gula?date=YYYY-MM-DD&search=...
  static Future<Response> ambilGula(
      {required String tanggal, String? keyword}) async {
    final token = await _getToken();
    final queryParams = {
      'date': tanggal,
      if (keyword != null && keyword.isNotEmpty) 'search': keyword,
    };

    return await ApiService.dio.get(
      '/api/gula',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// PUT /gula/<id>
  static Future<Response> updateGula(String id, HistoryItem item) async {
    final token = await _getToken();
    return await ApiService.dio.put(
      '/api/gula/$id',
      data: item.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// DELETE /gula/<id>
  static Future<Response> deleteGula(String id) async {
    final token = await _getToken();
    return await ApiService.dio.delete(
      '/api/gula/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
