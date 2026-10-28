import 'package:get/get.dart';

import '../../data/controllers/visitor_controller.dart';
import '../../data/providers/api_provider.dart';
import '../../data/repositories/visitor_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final api = ApiProvider();
    Get.put<ApiProvider>(api, permanent: true);
    Get.put<VisitorRepository>(
      VisitorRepository(RemoteVisitorApi(api)),
      permanent: true,
    );
    Get.put<VisitorController>(
      VisitorController(Get.find<VisitorRepository>()),
      permanent: true,
    );
  }
}
