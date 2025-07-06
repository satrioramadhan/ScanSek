import 'package:get/get.dart';
import '../controllers/berita_controller.dart';
import '../../../data/services/berita_service.dart';

class BeritaBinding extends Bindings {
  @override
  void dependencies() {
    // Register BeritaService as a service (singleton)
    Get.put<BeritaService>(BeritaService(), permanent: true);

    // Register BeritaController
    Get.lazyPut<BeritaController>(() => BeritaController());
  }
}
