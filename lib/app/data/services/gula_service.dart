import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/history_item.dart';

class GulaService {
  static Future<Response> tambahGula(HistoryItem item) async {
    return await ApiService.dioClient.post('/gula', data: item.toJson());
  }

  static Future<Response> ambilGula(
      {required String tanggal, String? keyword}) async {
    final queryParams = {
      'date': tanggal,
      if (keyword != null && keyword.isNotEmpty) 'search': keyword,
    };
    return await ApiService.dioClient
        .get('/gula', queryParameters: queryParams);
  }

  static Future<Response> updateGula(String id, HistoryItem item) async {
    return await ApiService.dioClient.put('/gula/$id', data: item.toJson());
  }

  static Future<Response> deleteGula(String id) async {
    return await ApiService.dioClient.delete('/gula/$id');
  }
}
