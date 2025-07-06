// app/services/berita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class BeritaModel {
  final String judul;
  final String link;
  final String thumbnail;
  final String description;
  final String pubDate;
  final String source;
  final String category;

  BeritaModel({
    required this.judul,
    required this.link,
    required this.thumbnail,
    required this.description,
    required this.pubDate,
    required this.source,
    required this.category,
  });

  factory BeritaModel.fromJson(Map<String, dynamic> json) {
    return BeritaModel(
      judul: json['judul'] ?? '',
      link: json['link'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      description: json['description'] ?? '',
      pubDate: json['pubDate'] ?? '',
      source: json['source'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class BeritaService extends GetxService {
  static const String baseUrl = 'http://172.184.197.28:5000/api';

  Future<List<BeritaModel>> getBeritaHariIni() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita-hari-ini'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => BeritaModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load berita: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil data berita: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }
}
