import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../themes/app_colors.dart';
import '../controllers/berita_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class BeritaView extends GetView<BeritaController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(controller.isWebViewMode.value
            ? "Dashboard Berita"
            : "Berita Kesehatan")),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.isWebViewMode.value
                    ? Icons.view_list
                    : Icons.dashboard),
                onPressed: controller.toggleViewMode,
                tooltip: controller.isWebViewMode.value
                    ? 'Tampilan List'
                    : 'Dashboard Analytics',
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isWebViewMode.value) {
          return _buildWebView();
        } else {
          return _buildFlutterUI();
        }
      }),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: controller.webViewController),
        Obx(() => controller.isLoading.value
            ? Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat Dashboard...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink()),
      ],
    );
  }

  Widget _buildFlutterUI() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat berita...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.beritaList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.newspaper,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Belum ada berita hari ini',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.refreshData,
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppColors.primary,
        child: ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.beritaList.length,
          separatorBuilder: (_, __) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final berita = controller.beritaList[index];
            return _buildBeritaCard(berita);
          },
        ),
      );
    });
  }

  Widget _buildBeritaCard(berita) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (berita.thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                berita.thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: AppColors.background,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                if (berita.category.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      berita.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                SizedBox(height: 8),

                // Judul
                Text(
                  berita.judul,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8),

                // Description
                if (berita.description.isNotEmpty)
                  Text(
                    berita.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                SizedBox(height: 12),

                // Source dan Date
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      berita.source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      controller.formatDate(berita.pubDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Button Baca
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.openBeritaDetail(berita.link),
                    icon: Icon(Icons.open_in_new, size: 16),
                    label: Text('Baca Selengkapnya'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
