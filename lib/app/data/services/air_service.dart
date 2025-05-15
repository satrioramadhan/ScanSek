import 'package:dio/dio.dart';
import 'api_service.dart';

class AirService {
  static Future<Response> ambilAir(String tanggal) async {
    return await ApiService.dio
        .get('/air', queryParameters: {'tanggal': tanggal});
  }

  static Future<Response> tambahJamMinum(String tanggal, String jam) async {
    return await ApiService.dio.post('/air', data: {
      'tanggal': tanggal,
      'jam': jam,
    });
  }

  static Future<Response> hapusHari(String tanggal) async {
    return await ApiService.dio.delete('/air/$tanggal');
  }

  static Future<Response> hapusJam(String tanggal, String jam) async {
    return await ApiService.dio.delete('/air/$tanggal/$jam');
  }
}
