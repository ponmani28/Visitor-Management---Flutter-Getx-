import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/controllers/visitor_controller.dart';
import '../../../data/models/visitor_model.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../visitor_list/views/visitor_list_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.find<HomeController>();
    final visitorController = Get.find<VisitorController>();

    if (!visitorController.hasLoaded.value && !visitorController.isLoading.value) {
      visitorController.load();
    }

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: homeController.currentIndex.value,
          children: <Widget>[
            DashboardView(
              onViewVisitors: ({VisitorStatus? status}) {
                visitorController.clearFilters();
                if (status != null) {
                  visitorController.setStatusFilter(status);
                }
                homeController.currentIndex.value = 1;
              },
              onOpenScanner: () => AppNavigator.openScanner(context),
            ),
            const VisitorListView(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: homeController.currentIndex.value,
            onTap: homeController.changeTab,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.space_dashboard_outlined),
                activeIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                activeIcon: Icon(Icons.people_alt_rounded),
                label: 'Visitors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                activeIcon: Icon(Icons.qr_code_scanner_rounded),
                label: 'Scan QR',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
