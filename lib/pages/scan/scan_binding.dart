import 'package:get/get.dart';
import 'scan_controller.dart';

class ScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ScanController>(ScanController(), permanent: true);
  }
}
