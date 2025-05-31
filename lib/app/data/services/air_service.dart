import 'package:dio/dio.dart';
import 'api_service.dart';

class AirService {
  static Future<Response> ambilAir(String tanggal) async {
    return await ApiService.dioClient
        .get('/air', queryParameters: {'tanggal': tanggal});
  }

  static Future<Response> tambahJamMinum(String tanggal, String jam) async {
    return await ApiService.dioClient.post('/air', data: {
      'tanggal': tanggal,
      'jam': jam,
    });
  }

  static Future<Response> hapusHari(String tanggal) async {
    return await ApiService.dioClient.delete('/air/$tanggal');
  }

  static Future<Response> hapusJam(String tanggal, String jam) async {
    return await ApiService.dioClient.delete('/air/$tanggal/$jam');
  }
}
