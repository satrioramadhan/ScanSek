import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/berita_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BeritaController extends GetxController {
  // Observable variables
  final isLoading = false.obs;
  final beritaList = <BeritaModel>[].obs;
  final isWebViewMode = false.obs;

  // WebView controller
  late WebViewController webViewController;

  // Service
  final BeritaService _beritaService = Get.find<BeritaService>();

  @override
  void onInit() {
    super.onInit();
    initializeWebView();
    loadBeritaData();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            // Kalau bukan IP lokal (dashboard), buka di browser
            if (!uri.host.contains('172.184.197.28')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) => isLoading.value = true,
          onPageFinished: (url) => isLoading.value = false,
          onWebResourceError: (error) {
            Get.snackbar(
              'Error',
              'Gagal memuat dashboard: ${error.description}',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('http://172.184.197.28:8501/'));
  }

  Future<void> loadBeritaData() async {
    if (isWebViewMode.value) return;

    isLoading.value = true;
    try {
      final data = await _beritaService.getBeritaHariIni();
      beritaList.value = data;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat berita: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleViewMode() {
    isWebViewMode.value = !isWebViewMode.value;
    if (!isWebViewMode.value) {
      // Refresh data when switching back to Flutter UI
      loadBeritaData();
    }
  }

  Future<void> refreshData() async {
    await loadBeritaData();
  }

  void openBeritaDetail(String url) async {
    try {
      final success = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        Get.snackbar('Gagal Membuka', 'Tidak bisa membuka link.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }

  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
