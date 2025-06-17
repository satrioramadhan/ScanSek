import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scan_sek/app/data/services/api_service.dart';

class LoginHistoryView extends StatelessWidget {
  final RxList<Map<String, dynamic>> loginHistory =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  Widget build(BuildContext context) {
    _fetchLoginHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Login"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (loginHistory.isEmpty) {
          return const Center(child: Text("Belum ada riwayat login."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: loginHistory.length,
          itemBuilder: (context, index) {
            final item = loginHistory[index];
            final dateStr = _formatDate(item["timestamp"]);
            final device = item["device"] ?? {};

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.devices),
                title: Text(
                    "${device["platform"] ?? "-"} ${device["version"] ?? ""}"),
                subtitle: Text("Model: ${device["model"] ?? "-"}"),
                trailing: Text(dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            );
          },
        );
      }),
    );
  }

  void _fetchLoginHistory() async {
    try {
      final res = await ApiService.dioClient.get('/auth/login-history');
      if (res.statusCode == 200 && res.data['success'] == true) {
        loginHistory.value = (res.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      print("❌ Gagal ambil login history: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy\nHH:mm').format(dateTime);
    } catch (_) {
      return "-";
    }
  }
}
