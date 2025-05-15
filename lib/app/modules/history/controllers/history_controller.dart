import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/history_item.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart'; // << TAMBAH INI
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/foundation.dart';

enum HistoryViewType { gula, air } // << TAMBAH ENUM

class HistoryController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.week.obs;
  var searchQuery = ''.obs;

  var allHistory = <HistoryItem>[].obs;
  var selectedView = HistoryViewType.gula.obs; // << TAMBAH INI

  var allWater = <Map<String, dynamic>>[].obs;
  var jamMinumHariIni = <String>[].obs; // << TAMBAH INI

  List<HistoryItem> get historyBySelectedDate {
    return allHistory.where((item) {
      final isSame = isSameDate(item.waktuInput, selectedDate.value);
      final matchesQuery = searchQuery.isEmpty ||
          item.namaMakanan
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());
      return isSame && matchesQuery;
    }).toList();
  }

  int get totalGulaHariItu =>
      historyBySelectedDate.fold(0, (sum, item) => sum + item.totalGula);

  int get totalAirHariItu {
    var data = allWater.firstWhereOrNull(
        (item) => isSameDate(item["tanggal"], selectedDate.value));
    return data != null ? data["jumlahGelas"] : 0;
  }

  void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  void changeSelectedDate(DateTime date) {
    selectedDate.value = date;
    Future.delayed(Duration(milliseconds: 300), () {
      getRiwayatFromAPI(date);
      getJamMinumFromAPI(date);
    });
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setView(HistoryViewType view) {
    selectedView.value = view;
  }

  String formatTanggal(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String konversiTotalHariItu() {
    double sendokTeh = totalGulaHariItu / 4.0;
    return sendokTeh.toStringAsFixed(1);
  }

  Future<void> getRiwayatFromAPI(DateTime tanggal) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(tanggal);
    try {
      final response = await GulaService.ambilGula(
          tanggal: tanggalStr, keyword: searchQuery.value);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        allHistory.value =
            data.map((json) => HistoryItem.fromJson(json)).toList();
      } else {
        if (kDebugMode) print("Gagal ambil data: ${response.data}");
        Get.snackbar(
            'Gagal', response.data['message'] ?? 'Tidak bisa ambil data');
      }
    } catch (e) {
      if (kDebugMode) print("Error ambil data: $e");
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }

  Future<void> getJamMinumFromAPI(DateTime tanggal) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(tanggal);
    try {
      final res = await AirService.ambilAir(tanggalStr);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final List<dynamic> riwayat = res.data['data']['riwayatJamMinum'] ?? [];
        jamMinumHariIni.value = List<String>.from(riwayat);
      } else {
        jamMinumHariIni.clear();
        if (kDebugMode) print("Gagal ambil air: ${res.data}");
      }
    } catch (e) {
      jamMinumHariIni.clear();
      if (kDebugMode) print("Error air: $e");
    }
  }

  Future<void> addHistoryItem({
    String namaMakanan = "",
    required int gulaPerBungkus,
    required int jumlahBungkus,
    int? isiPerBungkus,
  }) async {
    final newItem = HistoryItem(
      namaMakanan: namaMakanan,
      gulaPerBungkus: gulaPerBungkus,
      jumlahBungkus: jumlahBungkus,
      waktuInput: DateTime.now(),
      isiPerBungkus: isiPerBungkus,
    );

    try {
      final res = await GulaService.tambahGula(newItem);
      if (res.statusCode == 201 && res.data['success'] == true) {
        final itemBaru = HistoryItem.fromJson(res.data['data']);
        allHistory.add(itemBaru);
        Get.snackbar('Berhasil', 'Data berhasil disimpan');
      } else {
        if (kDebugMode) print("Gagal tambah data: ${res.data}");
        Get.snackbar('Gagal', res.data['message'] ?? 'Gagal simpan data');
      }
    } catch (e) {
      if (kDebugMode) print("Error tambah data: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat simpan: $e');
    }
  }

  Future<void> editHistoryItem(
    int index, {
    String namaMakanan = "",
    required int gulaPerBungkus,
    required int jumlahBungkus,
    int? isiPerBungkus,
  }) async {
    var item = historyBySelectedDate[index];
    int allIndex = allHistory.indexOf(item);
    if (allIndex != -1) {
      final updatedItem = HistoryItem(
        id: item.id,
        namaMakanan: namaMakanan,
        gulaPerBungkus: gulaPerBungkus,
        jumlahBungkus: jumlahBungkus,
        waktuInput: item.waktuInput,
        isiPerBungkus: isiPerBungkus,
      );

      try {
        final res = await GulaService.updateGula(item.id!, updatedItem);
        if (res.statusCode == 200 && res.data['success'] == true) {
          allHistory[allIndex] = updatedItem;
          Get.snackbar('Berhasil', 'Data berhasil diperbarui');
        } else {
          if (kDebugMode) print("Gagal update data: ${res.data}");
          Get.snackbar('Gagal', res.data['message'] ?? 'Gagal update data');
        }
      } catch (e) {
        if (kDebugMode) print("Error update data: $e");
        Get.snackbar('Error', 'Terjadi kesalahan saat update: $e');
      }
    }
  }

  Future<void> deleteHistoryItem(int index) async {
    var item = historyBySelectedDate[index];
    try {
      final res = await GulaService.deleteGula(item.id!);
      if (res.statusCode == 200 && res.data['success'] == true) {
        allHistory.remove(item);
        Get.snackbar('Berhasil', 'Data berhasil dihapus');
      } else {
        if (kDebugMode) print("Gagal hapus data: ${res.data}");
        Get.snackbar('Gagal', res.data['message'] ?? 'Gagal hapus data');
      }
    } catch (e) {
      if (kDebugMode) print("Error hapus data: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat hapus: $e');
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // minum
  Future<void> tambahJamMinum(String jam) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    try {
      final res = await AirService.tambahJamMinum(tanggalStr, jam);
      if (res.statusCode == 201 && res.data['success'] == true) {
        jamMinumHariIni.add(jam);
        Get.snackbar('Berhasil', 'Jam minum ditambahkan');
      } else {
        Get.snackbar('Gagal', res.data['message'] ?? 'Gagal tambah jam minum');
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }

  Future<void> hapusJamMinum(String jam) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    try {
      final res = await AirService.hapusJam(tanggalStr, jam);
      if (res.statusCode == 200 && res.data['success'] == true) {
        jamMinumHariIni.remove(jam);
        Get.snackbar('Berhasil', 'Jam minum berhasil dihapus');
      } else {
        Get.snackbar('Gagal', res.data['message'] ?? 'Gagal hapus jam minum');
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }
}
