import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/bindings/initial_binding.dart';
import 'app/core/config/app_config.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/controllers/visitor_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisitorManagementApp());
}

class VisitorManagementApp extends StatelessWidget {
  const VisitorManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: Routes.home,
      getPages: AppPages.routes,
      onInit: () {
        if (Get.isRegistered<VisitorController>()) {
          Get.find<VisitorController>().load();
        }
      },
    );
  }
}
