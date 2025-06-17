import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/history_item.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../home/controllers/home_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart';
import 'package:scan_sek/app/utils/conversion_helper.dart';

enum HistoryViewType { gula, air }

class HistoryController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.week.obs;
  var searchQuery = ''.obs;

  var allHistory = <HistoryItem>[].obs;
  var selectedView = HistoryViewType.gula.obs;

  var allWater = <Map<String, dynamic>>[].obs;
  var jamMinumHariIni = <String>[].obs;
  final dialogSudahDibuka = false.obs;

  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    ever(selectedDate, (_) => searchQuery.value = '');
  }

  @override
  void onClose() {
    searchQuery.value = '';
    dialogSudahDibuka.value = false;
    super.onClose();
  }

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
    return ConversionHelper.format(totalGulaHariItu.toDouble());
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
        SnackbarHelper.show(
            "Gagal", response.data['message'] ?? 'Tidak bisa ambil data',
            type: 'error');
      }
    } catch (e) {
      if (kDebugMode) print("Error ambil data: $e");
      SnackbarHelper.show("Error", 'Terjadi kesalahan: $e', type: 'error');
    }
  }

  Future<void> getJamMinumFromAPI(DateTime tanggal) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(tanggal);
    try {
      final res = await AirService.ambilAir(tanggalStr);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final List<dynamic> riwayat = res.data['data']['riwayatJamMinum'] ?? [];
        jamMinumHariIni.value = List<String>.from(riwayat);
        allWater.removeWhere((item) => isSameDate(item["tanggal"], tanggal));
        allWater.add({
          "tanggal": tanggal,
          "jumlahGelas": jamMinumHariIni.length,
        });
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
    String? isiPerBungkus,
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
        SnackbarHelper.show("Berhasil", "Data berhasil disimpan",
            type: "success");

        final homeController = Get.find<HomeController>();
        homeController.ambilDataHariIni();
        homeController.makananTerakhir.value =
            itemBaru.namaMakanan ?? "(tidak diketahui)";
        homeController.gulaMakananTerakhir.value = itemBaru.totalGula;
        homeController.waktuMakananTerakhir.value =
            DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                .format(itemBaru.waktuInput);
      } else {
        if (kDebugMode) print("Gagal tambah data: ${res.data}");
        SnackbarHelper.show("Gagal", res.data['message'] ?? 'Gagal simpan data',
            type: "error");
      }
    } catch (e) {
      if (kDebugMode) print("Error tambah data: $e");
      SnackbarHelper.show("Error", "Terjadi kesalahan saat simpan: $e",
          type: "error");
    }
  }

  Future<void> editHistoryItem(
    int index, {
    String namaMakanan = "",
    required int gulaPerBungkus,
    required int jumlahBungkus,
    String? isiPerBungkus,
  }) async {
    var item = historyBySelectedDate[index];
    int allIndex = allHistory.indexOf(item);
    if (allIndex != -1) {
      final updatedItem = item.copyWith(
        namaMakanan: namaMakanan,
        gulaPerBungkus: gulaPerBungkus,
        jumlahBungkus: jumlahBungkus,
        isiPerBungkus: isiPerBungkus,
      );

      try {
        final res = await GulaService.updateGula(item.id!, updatedItem);
        if (res.statusCode == 200 && res.data['success'] == true) {
          allHistory[allIndex] = updatedItem;
          SnackbarHelper.show("Berhasil", "Data berhasil diperbarui",
              type: "success");
        } else {
          if (kDebugMode) print("Gagal update data: ${res.data}");
          SnackbarHelper.show(
              "Gagal", res.data['message'] ?? 'Gagal update data',
              type: "error");
        }
      } catch (e) {
        if (kDebugMode) print("Error update data: $e");
        SnackbarHelper.show("Error", "Terjadi kesalahan saat update: $e",
            type: "error");
      }
    }
  }

  Future<void> deleteHistoryItem(int index) async {
    var item = historyBySelectedDate[index];
    try {
      final res = await GulaService.deleteGula(item.id!);
      if (res.statusCode == 200 && res.data['success'] == true) {
        allHistory.remove(item);
        SnackbarHelper.show("Berhasil", "Data berhasil dihapus",
            type: "success");
      } else {
        if (kDebugMode) print("Gagal hapus data: ${res.data}");
        SnackbarHelper.show("Gagal", res.data['message'] ?? 'Gagal hapus data',
            type: "error");
      }
    } catch (e) {
      if (kDebugMode) print("Error hapus data: $e");
      SnackbarHelper.show("Error", "Terjadi kesalahan saat hapus: $e",
          type: "error");
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> tambahJamMinum(String jam) async {
    if (jamMinumHariIni.contains(jam)) {
      SnackbarHelper.show("Gagal", "Kamu sudah menambahkan jam ini",
          type: "warning");
      return;
    }

    final tanggalStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    try {
      final res = await AirService.tambahJamMinum(tanggalStr, jam);
      if (res.statusCode == 201 && res.data['success'] == true) {
        jamMinumHariIni.add(jam);
        allWater.removeWhere(
            (item) => isSameDate(item["tanggal"], selectedDate.value));
        allWater.add({
          "tanggal": selectedDate.value,
          "jumlahGelas": jamMinumHariIni.length,
        });
        SnackbarHelper.show("Berhasil", "Jam minum ditambahkan",
            type: "success");
      } else {
        SnackbarHelper.show(
            "Gagal", res.data['message'] ?? 'Gagal tambah jam minum',
            type: "error");
      }
    } catch (e) {
      SnackbarHelper.show("Error", "Terjadi kesalahan: $e", type: "error");
    }
  }

  Future<void> hapusJamMinum(String jam) async {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    try {
      final res = await AirService.hapusJam(tanggalStr, jam);
      if (res.statusCode == 200 && res.data['success'] == true) {
        jamMinumHariIni.remove(jam);
        allWater.removeWhere(
            (item) => isSameDate(item["tanggal"], selectedDate.value));
        allWater.add({
          "tanggal": selectedDate.value,
          "jumlahGelas": jamMinumHariIni.length,
        });
        SnackbarHelper.show("Berhasil", "Jam minum berhasil dihapus",
            type: "success");
      } else {
        SnackbarHelper.show(
            "Gagal", res.data['message'] ?? 'Gagal hapus jam minum',
            type: "error");
      }
    } catch (e) {
      SnackbarHelper.show("Error", "Terjadi kesalahan: $e", type: "error");
    }
  }

  bool get isTodaySelected {
    final now = DateTime.now();
    return selectedDate.value.year == now.year &&
        selectedDate.value.month == now.month &&
        selectedDate.value.day == now.day;
  }
}
