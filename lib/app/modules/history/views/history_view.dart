import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/history_controller.dart';
import '../../../data/models/history_item.dart';
import '../../../themes/app_colors.dart';

class HistoryView extends GetView<HistoryController> {
  @override
  void _showTambahJamAirDialog(BuildContext context) {
    final TextEditingController jamController = TextEditingController(
      text: TimeOfDay.now().format(context), // << otomatis isi jam sekarang
    );

    Get.defaultDialog(
      title: "Tambah Jam Minum",
      content: Column(
        children: [
          TextField(
            controller: jamController,
            decoration: InputDecoration(hintText: "Contoh: 14:30"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final jam = jamController.text.trim();
              if (RegExp(r"^\d{2}:\d{2}$").hasMatch(jam)) {
                Get.back();
                Get.find<HistoryController>().tambahJamMinum(jam);
              } else {
                Get.snackbar("Format salah", "Gunakan format HH:mm");
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

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
        title: Obx(() => Text(
              controller.selectedView.value == HistoryViewType.gula
                  ? 'Riwayat Asupan Gula'
                  : 'Riwayat Minum Air',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
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
          Obx(() {
            return controller.selectedView.value == HistoryViewType.gula
                ? IconButton(
                    icon: const Icon(Icons.search, color: Colors.black87),
                    onPressed: () => _showSearchBottomSheet(context),
                  )
                : const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: Colors.black87),
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
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedView.value == HistoryViewType.gula &&
            controller.isTodaySelected) {
          return FloatingActionButton(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(context),
          );
        }
        return SizedBox.shrink();
      }),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Obx(() => TableCalendar(
                  firstDay: DateTime.utc(2022, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: controller.selectedDate.value,
                  selectedDayPredicate: (day) =>
                      isSameDay(controller.selectedDate.value, day),
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
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Obx(() => Text(
                  "Riwayat ${controller.formatTanggal(controller.selectedDate.value)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  fillColor: AppColors.primary,
                  selectedColor: Colors.white,
                  color: AppColors.primary,
                  selectedBorderColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  constraints:
                      const BoxConstraints(minHeight: 40, minWidth: 100),
                  isSelected: [
                    controller.selectedView.value == HistoryViewType.gula,
                    controller.selectedView.value == HistoryViewType.air,
                  ],
                  onPressed: (index) {
                    controller.setView(index == 0
                        ? HistoryViewType.gula
                        : HistoryViewType.air);
                    controller.pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  children: const [
                    Text('Gula', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Air', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (index) {
                controller.setView(
                    index == 0 ? HistoryViewType.gula : HistoryViewType.air);
              },
              children: [
                Obx(() => _buildListGula(controller.historyBySelectedDate)),
                Obx(() => _buildListAir(controller.jamMinumHariIni)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchBottomSheet(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cari Makanan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nama makanan...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.updateSearchQuery(val),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.updateSearchQuery('');
                    Get.back();
                  },
                  child: Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text("Tutup"),
                ),
              ],
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddEditDialog(BuildContext context,
      {int? index, HistoryItem? item, int? gulaDariOCR}) {
    final TextEditingController namaController =
        TextEditingController(text: item?.namaMakanan ?? '');
    final TextEditingController gulaController = TextEditingController(
      text: gulaDariOCR?.toString() ?? item?.gulaPerBungkus.toString() ?? '',
    );
    final TextEditingController jumlahController =
        TextEditingController(text: item?.jumlahBungkus.toString() ?? '');
    final TextEditingController isiController =
        TextEditingController(text: item?.isiPerBungkus?.toString() ?? '');
    final TextEditingController konversiController = TextEditingController();

    void updateKonversi() {
      final gula = int.tryParse(gulaController.text) ?? 0;
      final jumlah = int.tryParse(jumlahController.text) ?? 0;
      final konversi = (gula * jumlah) / 4.0;
      konversiController.text = "${konversi.toStringAsFixed(1)} sdt";
    }

    gulaController.addListener(updateKonversi);
    jumlahController.addListener(updateKonversi);
    updateKonversi();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                index == null ? "Tambah Makanan" : "Edit Makanan",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: namaController,
                decoration:
                    const InputDecoration(labelText: "Nama Makanan (opsional)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gulaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Kandungan Gula per Bungkus (gram)*"),
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
                decoration: const InputDecoration(
                    labelText: "Isi Makanan per Bungkus (opsional)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: konversiController,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Total Gula (Sendok Teh)",
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Batal"),
                    onPressed: () => Get.back(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      final int gula = int.tryParse(gulaController.text) ?? 0;
                      final int jumlah =
                          int.tryParse(jumlahController.text) ?? 0;
                      final String nama = namaController.text.trim().isNotEmpty
                          ? namaController.text.trim()
                          : "(kamu ga ngisiin)";
                      final int isi =
                          int.tryParse(isiController.text) ?? 0; // default 0

                      if (gula <= 0 || jumlah <= 0) {
                        Get.snackbar(
                          "Error",
                          "Kandungan gula dan jumlah bungkus harus diisi!",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      if (index == null) {
                        controller.addHistoryItem(
                          namaMakanan: nama,
                          gulaPerBungkus: gula,
                          jumlahBungkus: jumlah,
                          isiPerBungkus: isi,
                        );
                      } else {
                        controller.editHistoryItem(
                          index,
                          namaMakanan: nama,
                          gulaPerBungkus: gula,
                          jumlahBungkus: jumlah,
                          isiPerBungkus: isi,
                        );
                      }

                      Get.back();
                    },
                    child: const Text("Simpan",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListGula(List<HistoryItem> items) {
    return Column(
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        if (!controller.isTodaySelected)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Data tidak dapat diubah di tanggal ini",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text("Belum ada riwayat makanan 🍃",
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          item.namaMakanan.isNotEmpty
                              ? item.namaMakanan
                              : "Makanan tidak diketahui",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.isiPerBungkus != null)
                              Text(
                                  "Isi Perbungkus: ${item.isiPerBungkus} gram"),
                            Text("Jumlah Makan: ${item.jumlahBungkus} bungkus"),
                            Text(
                                "Kandungan Gula: ${item.gulaPerBungkus} gram/bungkus"),
                            Text(
                                "Total Gula: ${item.totalGula} gram (≈ ${item.konversiSendokTeh.toStringAsFixed(1)} sdt)"),
                            Text("Waktu Input: ${item.formattedTime}"),
                          ],
                        ),
                        trailing: controller.isTodaySelected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: AppColors.primary),
                                    onPressed: () => _showAddEditDialog(
                                        Get.context!,
                                        index: index,
                                        item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showConfirmDelete(context, index),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListAir(List<String> jamList) {
    final jamList = controller.jamMinumHariIni;

    return Column(
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Total minum air: ${controller.totalAirHariItu} gelas",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (controller.isTodaySelected)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 8),
              child: FloatingActionButton.small(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.add, color: Colors.white),
                onPressed: () => _showTambahJamAirDialog(Get.context!),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: jamList.isEmpty
              ? Center(
                  child: Text("Belum ada riwayat minum air 💧",
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: jamList.length,
                  itemBuilder: (context, index) {
                    final jam = jamList[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.local_drink,
                            color: Colors.lightBlue),
                        title: Text("Minum air pukul $jam"),
                        trailing: controller.isTodaySelected
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showConfirmDeleteJam(context, jam),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showConfirmDelete(BuildContext context, int index) {
    Get.defaultDialog(
      title: "Hapus Data?",
      middleText: "Apakah kamu yakin ingin menghapus data ini?",
      textCancel: "Batal",
      textConfirm: "Hapus",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteHistoryItem(index);
      },
    );
  }

  void _showConfirmDeleteJam(BuildContext context, String jam) {
    Get.defaultDialog(
      title: "Hapus Jam Minum?",
      middleText: "Yakin ingin hapus jam $jam?",
      textCancel: "Batal",
      textConfirm: "Hapus",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.hapusJamMinum(jam);
      },
    );
  }
}
