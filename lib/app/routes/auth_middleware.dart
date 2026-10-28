import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/controllers/auth_controller.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (Get.find<AuthController>().isAuthenticated) return null;
    return const RouteSettings(name: Routes.login);
  }
}
