import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/history_item.dart';
import 'package:table_calendar/table_calendar.dart';


class HistoryController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.week.obs;

  var allHistory = <HistoryItem>[
    HistoryItem(
      namaMakanan: "Teh Botol Sosro",
      gulaPerBungkus: 19,
      jumlahBungkus: 1,
      waktuInput: DateTime.now().subtract(Duration(hours: 2)),
    ),
    HistoryItem(
      namaMakanan: "Chitato Sapi Panggang",
      gulaPerBungkus: 3,
      jumlahBungkus: 2,
      waktuInput: DateTime.now().subtract(Duration(hours: 4)),
    ),
    HistoryItem(
      namaMakanan: "Es Kopi Susu Gula Aren",
      gulaPerBungkus: 25,
      jumlahBungkus: 1,
      waktuInput: DateTime.now().subtract(Duration(days: 1, hours: 1)),
    ),
  ].obs;

  var allWater = <Map<String, dynamic>>[
    {
      "tanggal": DateTime.now(),
      "jumlahGelas": 5,
    },
    {
      "tanggal": DateTime.now().subtract(Duration(days: 1)),
      "jumlahGelas": 7,
    },
  ].obs;

  List<HistoryItem> get historyBySelectedDate {
    return allHistory.where((item) => isSameDate(item.waktuInput, selectedDate.value)).toList();
  }

  int get totalGulaHariItu {
    return historyBySelectedDate.fold(0, (sum, item) => sum + item.totalGula);
  }

  int get totalAirHariItu {
    var data = allWater.firstWhereOrNull((item) => isSameDate(item["tanggal"], selectedDate.value));
    return data != null ? data["jumlahGelas"] : 0;
  }

    void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  void changeSelectedDate(DateTime date) {
    selectedDate.value = date;
  }


  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatTanggal(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String konversiTotalHariItu() {
    double sendokTeh = totalGulaHariItu / 4.0;
    return sendokTeh.toStringAsFixed(1);
  }

  void addHistoryItem({
    String namaMakanan = "",
    required int gulaPerBungkus,
    required int jumlahBungkus,
    int? isiPerBungkus,
  }) {
    final newItem = HistoryItem(
      namaMakanan: namaMakanan,
      gulaPerBungkus: gulaPerBungkus,
      jumlahBungkus: jumlahBungkus,
      waktuInput: DateTime.now(),
      isiPerBungkus: isiPerBungkus,
    );
    allHistory.add(newItem);
  }

  void editHistoryItem(
    int index, {
    String namaMakanan = "",
    required int gulaPerBungkus,
    required int jumlahBungkus,
    int? isiPerBungkus,
  }) {
    var item = historyBySelectedDate[index];
    int allIndex = allHistory.indexOf(item);
    if (allIndex != -1) {
      allHistory[allIndex] = HistoryItem(
        namaMakanan: namaMakanan,
        gulaPerBungkus: gulaPerBungkus,
        jumlahBungkus: jumlahBungkus,
        waktuInput: item.waktuInput,
        isiPerBungkus: isiPerBungkus,
      );
    }
  }

  void deleteHistoryItem(int index) {
    var item = historyBySelectedDate[index];
    allHistory.remove(item);
  }

  
}
