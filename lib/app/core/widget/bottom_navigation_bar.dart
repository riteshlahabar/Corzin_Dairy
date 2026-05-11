import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../modules/doctor/controllers/doctor_controller.dart';
import '../../modules/doctor/views/doctor_appointments_nearby_view.dart';
import '../../modules/fetch_location/views/fetch_location_view.dart';
import '../../modules/feeding/views/feeding_history_view.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/milk/views/milk_history_view.dart';
import '../../modules/pan/views/pan_management_view.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/shop/controllers/shop_controller.dart';
import '../../modules/shop/views/my_orders_view.dart';
import '../../modules/shop/views/shop_view.dart';
import '../../routes/app_pages.dart';
import '../services/session_service.dart';
import '../theme/colors.dart';

class BottomNavController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final RxInt currentIndex = 0.obs;
  final Rx<Widget?> activeDrawerPage = Rx<Widget?>(null);
  final List<int> _tabBackStack = <int>[0];

  void changeTab(int index) {
    if (index == 2) return;
    activeDrawerPage.value = null;
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    if (_tabBackStack.isEmpty || _tabBackStack.last != index) {
      _tabBackStack.add(index);
      if (_tabBackStack.length > 32) {
        _tabBackStack.removeAt(0);
      }
    }
  }

  void resetTabHistory() {
    _tabBackStack
      ..clear()
      ..add(currentIndex.value);
  }

  void openRootDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  bool handleRootBackPress() {
    if (closeDrawerPage()) {
      return true;
    }

    if (_tabBackStack.length > 1) {
      _tabBackStack.removeLast();
      currentIndex.value = _tabBackStack.last;
      return true;
    }

    if (currentIndex.value != 0) {
      currentIndex.value = 0;
      _tabBackStack
        ..clear()
        ..add(0);
      return true;
    }

    return false;
  }

  bool closeDrawerPage() {
    if (activeDrawerPage.value == null) return false;
    activeDrawerPage.value = null;
    return true;
  }

  void openAddAction() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 54,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Text(
              'quick_add'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'quick_add_desc'.tr,
              style: TextStyle(fontSize: 13, color: AppColors.grey.shade700),
            ),
            const SizedBox(height: 18),
            _sheetAction(
              icon: Icons.local_drink_rounded,
              title: 'add_milk'.tr,
              onTap: () {
                Get.back();
                openDrawerRoute(Routes.MILK);
              },
            ),
            const SizedBox(height: 12),
            _sheetAction(
              icon: Icons.grass_rounded,
              title: 'add_feeding'.tr,
              onTap: () {
                Get.back();
                openDrawerRoute(Routes.FEEDING);
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> logout() async {
    await SessionService.logout();
    Get.offAllNamed(Routes.SPLASH);
  }

  void openDrawerRoute(String routeName) {
    final route = AppPages.routes.firstWhereOrNull(
      (item) => item.name == routeName,
    );
    if (route == null) {
      Get.toNamed(routeName);
      return;
    }

    final dynamic dynamicRoute = route;
    try {
      final binding = dynamicRoute.binding;
      if (binding is Bindings) {
        binding.dependencies();
      }
    } catch (_) {}
    try {
      final bindings = dynamicRoute.bindings;
      if (bindings is List<Bindings>) {
        for (final item in bindings) {
          item.dependencies();
        }
      }
    } catch (_) {}

    activeDrawerPage.value = route.page();
  }

  void openDrawerPage(Widget page) {
    activeDrawerPage.value = page;
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class MainBottomNavView extends StatefulWidget {
  const MainBottomNavView({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainBottomNavView> createState() => _MainBottomNavViewState();
}

class _MainBottomNavViewState extends State<MainBottomNavView> {
  late final BottomNavController controller;

  T _resetAndPut<T extends GetxController>(
    T Function() builder, {
    bool permanent = false,
  }) {
    if (Get.isRegistered<T>()) {
      Get.delete<T>(force: true);
    }
    return Get.put<T>(builder(), permanent: permanent);
  }

  @override
  void initState() {
    super.initState();
    controller = _resetAndPut<BottomNavController>(
      () => BottomNavController(),
      permanent: true,
    );
    controller.currentIndex.value = widget.initialIndex;
    controller.resetTabHistory();
    _resetAndPut<HomeController>(() => HomeController(), permanent: true);
    _resetAndPut<DoctorController>(() => DoctorController(), permanent: true);
    _resetAndPut<ShopController>(() => ShopController(), permanent: true);
    _resetAndPut<ProfileController>(() => ProfileController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeView(),
      const DoctorAppointmentsNearbyView(),
      const SizedBox(),
      const ShopView(),
      const ProfileView(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (controller.scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return;
        }

        final handled = controller.handleRootBackPress();
        if (!handled) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: false,
        drawer: _buildDrawer(context, controller),
        body: Obx(() {
          final drawerPage = controller.activeDrawerPage.value;
          return Stack(
            children: [
              drawerPage ??
                  IndexedStack(
                    index: controller.currentIndex.value,
                    children: pages,
                  ),
              if (drawerPage != null)
                Positioned(
                  top: MediaQuery.of(context).viewPadding.top + 8,
                  right: 12,
                  child: IconButton(
                    onPressed: controller.openRootDrawer,
                    icon: const Icon(Icons.menu_rounded),
                    color: AppColors.white,
                    splashRadius: 1,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),
            ],
          );
        }),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 1,
          onPressed: controller.openAddAction,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Obx(
          () => BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: AppColors.white,
            elevation: 10,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  _navItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'home'.tr,
                    isSelected: controller.currentIndex.value == 0,
                    onTap: () => controller.changeTab(0),
                  ),
                  _navItem(
                    icon: Icons.medical_services_outlined,
                    selectedIcon: Icons.medical_services_rounded,
                    label: 'doctor'.tr,
                    isSelected: controller.currentIndex.value == 1,
                    onTap: () => controller.changeTab(1),
                  ),
                  const SizedBox(width: 44),
                  _navItem(
                    icon: Icons.storefront_outlined,
                    selectedIcon: Icons.storefront_rounded,
                    label: 'shop'.tr,
                    isSelected: controller.currentIndex.value == 3,
                    onTap: () => controller.changeTab(3),
                  ),
                  _navItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'profile'.tr,
                    isSelected: controller.currentIndex.value == 4,
                    onTap: () => controller.changeTab(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, BottomNavController controller) {
    final homeController = Get.find<HomeController>();
    return Drawer(
      width: Get.width * 0.74,
      backgroundColor: const Color(0xFFF4FAF4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context, homeController),
          Expanded(
            child: Container(
              color: const Color(0xFFF4FAF4),
              child: SafeArea(
                top: false,
                bottom: true,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _drawerTile(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'add_animal'.tr,
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.ANIMAL);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.pets_rounded,
                      title: 'Animal list',
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.ANIMAL_HISTORY);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'manage_animal'.tr,
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.MANAGE_ANIMAL);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.account_tree_outlined,
                      title: 'Create PAN',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(const PanManagementView());
                      },
                    ),
                    _drawerTile(
                      icon: Icons.list_alt_rounded,
                      title: 'PAN List',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(
                          const PanManagementView(
                            mode: PanManagementMode.manage,
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.local_drink_outlined,
                      title: 'Milk Record',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(const MilkHistoryView());
                      },
                    ),
                    _drawerTile(
                      icon: Icons.tune_rounded,
                      title: 'Add Feed Type',
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.FEED_SETTINGS);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Diet Plan',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(
                          const FeedingHistoryView(initialTab: 1),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.grass_rounded,
                      title: 'Feeding Record',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(
                          const FeedingHistoryView(initialTab: 0),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.storefront_outlined,
                      title: 'add_dairy'.tr,
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.DAIRY);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.payments_outlined,
                      title: 'Dairy Payment',
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.PAYMENT);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.health_and_safety_outlined,
                      title: 'health'.tr,
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.HEALTH);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(const MyOrdersView());
                      },
                    ),
                    _drawerTile(
                      icon: Icons.translate_rounded,
                      title: 'change_language'.tr,
                      onTap: () {
                        Get.back();
                        Get.toNamed(
                          Routes.LANGUAGE,
                          arguments: {'fromDrawer': true},
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.location_searching_rounded,
                      title: 'Fetch Location',
                      onTap: () {
                        Get.back();
                        controller.openDrawerPage(const FetchLocationView());
                      },
                    ),
                    _drawerTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'upgrade_plan'.tr,
                      onTap: () {
                        Get.back();
                        controller.openDrawerRoute(Routes.UPGRADE);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.logout_rounded,
                      title: 'logout'.tr,
                      onTap: () async {
                        Get.back();
                        await controller.logout();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    HomeController homeController,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.of(context).viewPadding.top + 14,
        14,
        10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F5F30), Color(0xFF2E7A41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Obx(() {
        final farmerName = homeController.farmerName.value.trim().isEmpty
            ? 'guest'.tr
            : homeController.farmerName.value;
        final farmerMobile = homeController.farmerMobile.value.trim();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      farmerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (farmerMobile.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.call_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              farmerMobile,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title),
    onTap: onTap,
  );

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppColors.primary : AppColors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
