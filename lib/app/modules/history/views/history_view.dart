import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/history_controller.dart';
import '../../../data/models/history_item.dart';
import '../../../themes/app_colors.dart';

class HistoryView extends GetView<HistoryController> {
  
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args['openAddDialog'] == true) {
        _showAddEditDialog(context, gulaDariOCR: args['gulaGram']);
      }
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Asupan Gula', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.black87),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime(2022),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                controller.changeSelectedDate(pickedDate);
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditDialog(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Obx(() => TableCalendar(
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: controller.selectedDate.value,
              selectedDayPredicate: (day) => isSameDay(controller.selectedDate.value, day),
              onDaySelected: (selectedDay, focusedDay) {
                controller.changeSelectedDate(selectedDay);
              },
              calendarFormat: controller.calendarFormat.value,
              onFormatChanged: (format) {
                controller.changeCalendarFormat(format);
              },
              headerVisible: false,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayTextStyle: const TextStyle(color: Colors.black),
              ),
            )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Obx(() => Text(
              "Riwayat ${controller.formatTanggal(controller.selectedDate.value)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            )),
          ),
          Expanded(
            child: Obx(() {
              List<HistoryItem> items = controller.historyBySelectedDate;

              return Column(
                children: [
                  // Card Total Konsumsi
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total konsumsi gula: ${controller.totalGulaHariItu} gram (≈ ${controller.konversiTotalHariItu()} sdt)",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total minum air: ${controller.totalAirHariItu} gelas",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // List Riwayat Makanan
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              "Belum ada riwayat makanan 🍃",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                child: ListTile(
                                  title: Text(
                                    item.namaMakanan.isNotEmpty ? item.namaMakanan : "Makanan tidak diketahui",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.isiPerBungkus != null)
                                        Text("Isi Perungkus: ${item.isiPerBungkus} gram"),
                                      Text("Jumlah Makan: ${item.jumlahBungkus} bungkus"),
                                      Text("Kandungan Gula: ${item.gulaPerBungkus} gram/bungkus"),
                                      Text("Total Gula: ${item.totalGula} gram (≈ ${item.konversiSendokTeh.toStringAsFixed(1)} sdt)"),
                                      Text("Waktu Input: ${item.formattedTime}"),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.primary),
                                        onPressed: () => _showAddEditDialog(context, index: index, item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => controller.deleteHistoryItem(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

// _showAddEditDialog diubah biar lengkap:
void _showAddEditDialog(BuildContext context, {int? index, HistoryItem? item, int? gulaDariOCR}) {
  final TextEditingController namaController = TextEditingController(text: item?.namaMakanan ?? '');
  final TextEditingController gulaController = TextEditingController(
    text: gulaDariOCR?.toString() ?? item?.gulaPerBungkus.toString() ?? '',
  );
  final TextEditingController jumlahController = TextEditingController(text: item?.jumlahBungkus.toString() ?? '');
  final TextEditingController isiController = TextEditingController(text: item?.isiPerBungkus?.toString() ?? '');

  Get.defaultDialog(
    title: index == null ? "Tambah Makanan" : "Edit Makanan",
    content: Column(
      children: [
        TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: "Nama Makanan (opsional)"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: gulaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Kandungan Gula per Bungkus (gram)*"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: jumlahController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Jumlah Bungkus*"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: isiController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Isi Makanan per Bungkus (opsional)"),
        ),
      ],
    ),
    textConfirm: "Simpan",
    textCancel: "Batal",
    confirmTextColor: Colors.white,
    onConfirm: () {
      int gula = int.tryParse(gulaController.text) ?? 0;
      int jumlah = int.tryParse(jumlahController.text) ?? 0;
      int? isi = isiController.text.isNotEmpty ? int.tryParse(isiController.text) : null;

      if (gula <= 0 || jumlah <= 0) {
        Get.snackbar("Error", "Kandungan gula dan jumlah bungkus harus diisi dengan benar!",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      if (index == null) {
        controller.addHistoryItem(
          namaMakanan: namaController.text,
          gulaPerBungkus: gula,
          jumlahBungkus: jumlah,
          isiPerBungkus: isi,
        );
      } else {
        controller.editHistoryItem(
          index,
          namaMakanan: namaController.text,
          gulaPerBungkus: gula,
          jumlahBungkus: jumlah,
          isiPerBungkus: isi,
        );
      }
      Get.back();
    },
  );
}
}
