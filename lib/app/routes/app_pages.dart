import 'package:get/get.dart';

import '../modules/auth/views/login_view.dart';
import '../modules/home_wrapper/bindings/home_binding.dart';
import '../modules/home_wrapper/views/home_view.dart';
import '../modules/qr_scanner/bindings/qr_scanner_binding.dart';
import '../modules/qr_scanner/views/qr_scanner_view.dart';
import '../modules/visitor_details/bindings/visitor_details_binding.dart';
import '../modules/visitor_details/views/visitor_details_view.dart';
import '../modules/visitor_form/bindings/visitor_form_binding.dart';
import '../modules/visitor_form/views/visitor_form_view.dart';
import 'auth_middleware.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: Routes.visitorForm,
      page: () => VisitorFormView(visitor: Get.arguments),
      binding: VisitorFormBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: Routes.visitorDetails,
      page: () => VisitorDetailsView(visitor: Get.arguments),
      binding: VisitorDetailsBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: Routes.qrScanner,
      page: () => const QrScannerView(),
      binding: QrScannerBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
