import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/visitor_model.dart';

abstract class Routes {
  static const home = '/home';
  static const visitorForm = '/visitor-form';
  static const visitorDetails = '/visitor-details';
  static const qrScanner = '/qr-scanner';
}

abstract final class AppNavigator {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }

  static Future<dynamic> openVisitorForm(
    BuildContext context, {
    Visitor? visitor,
  }) async {
    return Get.toNamed(Routes.visitorForm, arguments: visitor);
  }

  static Future<void> openVisitorDetails(
    BuildContext context,
    Visitor visitor,
  ) async {
    return Get.toNamed(Routes.visitorDetails, arguments: visitor);
  }

  static Future<void> openScanner(BuildContext context) async {
    return Get.toNamed(Routes.qrScanner);
  }
}
