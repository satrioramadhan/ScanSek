import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import '../controllers/berita_controller.dart';

class BeritaView extends GetView<BeritaController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Berita Kesehatan"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: 5, // Dummy count
        separatorBuilder: (_, __) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail dummy
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    'https://source.unsplash.com/400x200/?fruit&sig=$index',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Judul Berita Dummy ke-${index + 1}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Sumber: sehatnews.com · 2 Mei 2025",
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Get.snackbar("Fitur belum aktif",
                                "Tunggu update scraping ya bro 😎");
                          },
                          child: Text("Baca Selengkapnya"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
