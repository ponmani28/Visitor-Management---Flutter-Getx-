import 'package:get/get.dart';

import '../../../data/controllers/visitor_controller.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index == 2) {
      Get.toNamed('/qr-scanner');
      return;
    }
    if (index < 0 || index > 1) return;
    currentIndex.value = index;
  }

  void goToVisitors({dynamic status}) {
    if (Get.isRegistered<VisitorController>()) {
      final controller = Get.find<VisitorController>();
      controller.clearFilters();
      if (status != null) {
        controller.setStatusFilter(status);
      }
    }
    currentIndex.value = 1;
  }
}
