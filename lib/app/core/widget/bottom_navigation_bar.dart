import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../modules/doctor/controllers/doctor_controller.dart';
import '../../modules/doctor/views/doctor_appointments_nearby_view.dart';
import '../../modules/fetch_location/views/fetch_location_view.dart';
import '../../modules/feeding/views/feeding_history_view.dart';
import '../../modules/health/controllers/health_controller.dart';
import '../../modules/health/views/health_view.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/milk/views/milk_history_view.dart';
import '../../modules/pan/views/pan_management_view.dart';
import '../../modules/payment/controllers/payment_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/reports/views/livestock_report_view.dart';
import '../../modules/shop/controllers/shop_controller.dart';
// import '../../modules/shop/views/my_orders_view.dart';
import '../../modules/upgrade/controllers/upgrade_controller.dart';
import '../../modules/upgrade/views/upgrade_view.dart';
import '../../routes/app_pages.dart';
import '../services/session_service.dart';
import '../theme/colors.dart';

class BottomNavController extends GetxController with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final RxInt currentIndex = 0.obs;
  final Rx<Widget?> activeDrawerPage = Rx<Widget?>(null);
  final List<int> _tabBackStack = <int>[0];
  final List<Widget> _drawerPageStack = <Widget>[];
  Timer? _silentSyncTimer;
  bool _silentSyncInFlight = false;
  int _silentSyncTick = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startSilentSyncTimer();
    unawaited(_runSilentSync(force: true));
  }

  @override
  void onClose() {
    _silentSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runSilentSync(force: true));
    }
  }

  void changeTab(int index) {
    if (index == 2) return;
    if (_isPlanLocked) {
      _showPlanLockedMessage();
      openDrawerRoute(Routes.UPGRADE);
      return;
    }
    activeDrawerPage.value = null;
    _drawerPageStack.clear();
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    if (_tabBackStack.isEmpty || _tabBackStack.last != index) {
      _tabBackStack.add(index);
      if (_tabBackStack.length > 32) {
        _tabBackStack.removeAt(0);
      }
    }
    unawaited(_runSilentSync(force: true));
  }

  void resetTabHistory() {
    _tabBackStack
      ..clear()
      ..add(currentIndex.value);
  }

  void openRootDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void _startSilentSyncTimer() {
    _silentSyncTimer?.cancel();
    _silentSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_runSilentSync());
    });
  }

  Future<void> _runSilentSync({bool force = false}) async {
    if (_silentSyncInFlight && !force) return;
    _silentSyncInFlight = true;
    try {
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshDashboard(silent: true);
      }

      if (Get.isRegistered<DoctorController>()) {
        await Get.find<DoctorController>().silentRefresh();
      }

      if (Get.isRegistered<PaymentController>()) {
        await Get.find<PaymentController>().loadPayments(silent: true);
      }

      _silentSyncTick++;
      if (_silentSyncTick % 3 == 0 && Get.isRegistered<ShopController>()) {
        await Get.find<ShopController>().loadShopData();
      }
      if (_silentSyncTick % 3 == 0 && Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().loadProfile();
      }
    } catch (_) {
      // Silent background sync should never interrupt UI flow.
    } finally {
      _silentSyncInFlight = false;
    }
  }

  void runSilentSyncNow() {
    unawaited(_runSilentSync(force: true));
  }

  bool handleRootBackPress() {
    if (closeDrawerPage()) {
      return true;
    }

    if (_tabBackStack.length > 1) {
      _tabBackStack.removeLast();
      currentIndex.value = _tabBackStack.last;
      unawaited(_runSilentSync(force: true));
      return true;
    }

    if (currentIndex.value != 0) {
      currentIndex.value = 0;
      _tabBackStack
        ..clear()
        ..add(0);
      unawaited(_runSilentSync(force: true));
      return true;
    }

    return false;
  }

  bool closeDrawerPage() {
    if (activeDrawerPage.value != null &&
        (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
      unawaited(_runSilentSync(force: true));
      return true;
    }

    if (_drawerPageStack.isNotEmpty) {
      activeDrawerPage.value = _drawerPageStack.removeLast();
      unawaited(_runSilentSync(force: true));
      return true;
    }

    if (activeDrawerPage.value == null) return false;
    activeDrawerPage.value = null;
    _drawerPageStack.clear();
    unawaited(_runSilentSync(force: true));
    return true;
  }

  bool popRouteOrCloseDrawerPage() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      unawaited(_runSilentSync(force: true));
      return true;
    }

    return closeDrawerPage();
  }

  void openAddAction() {
    if (_isPlanLocked) {
      _showPlanLockedMessage();
      openDrawerRoute(Routes.UPGRADE);
      return;
    }
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
    if (_isPlanLocked && routeName != Routes.UPGRADE) {
      _showPlanLockedMessage();
      openDrawerRoute(Routes.UPGRADE);
      return;
    }
    final route = AppPages.routes.firstWhereOrNull(
      (item) => item.name == routeName,
    );
    if (route == null) {
      Get.toNamed(routeName);
      unawaited(_runSilentSync(force: true));
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
    _drawerPageStack.clear();
    unawaited(_runSilentSync(force: true));
  }

  void openDrawerPage(Widget page) {
    if (_isPlanLocked) {
      _showPlanLockedMessage();
      openDrawerRoute(Routes.UPGRADE);
      return;
    }
    activeDrawerPage.value = page;
    _drawerPageStack.clear();
    unawaited(_runSilentSync(force: true));
  }

  void openNestedDrawerPage(Widget page) {
    if (_isPlanLocked) {
      _showPlanLockedMessage();
      openDrawerRoute(Routes.UPGRADE);
      return;
    }
    final current = activeDrawerPage.value;
    if (current != null) {
      _drawerPageStack.add(current);
    }
    activeDrawerPage.value = page;
    unawaited(_runSilentSync(force: true));
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

  bool get _isPlanLocked =>
      Get.isRegistered<HomeController>() &&
      Get.find<HomeController>().isPlanLocked.value;

  void _showPlanLockedMessage() {
    final message = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().planLockMessage.value
        : '';
    Get.snackbar(
      'upgrade_plan'.tr,
      message.trim().isEmpty
          ? 'plan_expired_contact_admin'.tr
          : message,
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
    _resetAndPut<UpgradeController>(() => UpgradeController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final List<Widget> pages = [
      const HomeView(),
      const DoctorAppointmentsNearbyView(),
      const SizedBox(),
      // Temporary swap: hide Shop tab and show Livestock Report tab.
      const LivestockReportView(),
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
        resizeToAvoidBottomInset: true,
        drawer: _buildDrawer(context, controller),
        body: Obx(() {
          final drawerPage = controller.activeDrawerPage.value;
          final planLocked = Get.find<HomeController>().isPlanLocked.value;
          return Stack(
            children: [
              planLocked
                  ? const UpgradeView()
                  : drawerPage ??
                  IndexedStack(
                    index: controller.currentIndex.value,
                    children: pages,
                  ),
              if (drawerPage != null || planLocked)
                Positioned(
                  top: MediaQuery.of(context).viewPadding.top + 8,
                  right: 12,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.openRootDrawer,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.menu,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        bottomNavigationBar: keyboardVisible
            ? null
            : Obx(
                () => BottomAppBar(
                  color: AppColors.white,
                  elevation: 10,
                  height: 60,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 60,
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
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: controller.openAddAction,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.96),
                                      AppColors.primary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Temporary swap: Shop tab hidden in bottom navigation.
                        _navItem(
                          icon: Icons.summarize_outlined,
                          selectedIcon: Icons.summarize_rounded,
                          label: 'menu_report'.tr,
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
                    _drawerGroup(
                      icon: Icons.pets_rounded,
                      title: 'menu_animal'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'add_animal'.tr,
                          icon: Icons.add_circle_outline_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.ANIMAL);
                          },
                        ),
                        _drawerSubTile(
                          title: 'animal_list'.tr,
                          icon: Icons.list_alt_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.ANIMAL_HISTORY);
                          },
                        ),
                        _drawerSubTile(
                          title: 'manage_animal'.tr,
                          icon: Icons.manage_accounts_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.MANAGE_ANIMAL);
                          },
                        ),
                        _drawerSubTile(
                          title: 'manage_pregnancy'.tr,
                          icon: Icons.favorite_border_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.MANAGE_PREGNANCY);
                          },
                        ),
                        _drawerSubTile(
                          title: 'animal_for_sale'.tr,
                          icon: Icons.sell_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.ANIMAL_FOR_SALE);
                          },
                        ),
                        _drawerSubTile(
                          title: 'buy_animal'.tr,
                          icon: Icons.shopping_cart_checkout_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.BUY_ANIMAL);
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.account_tree_outlined,
                      title: 'menu_pan'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'create_pan'.tr,
                          icon: Icons.add_box_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(const PanManagementView());
                          },
                        ),
                        _drawerSubTile(
                          title: 'pan_list'.tr,
                          icon: Icons.list_alt_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(
                              const PanManagementView(
                                mode: PanManagementMode.manage,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.local_drink_outlined,
                      title: 'menu_milk'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'milk_record'.tr,
                          icon: Icons.local_drink_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(const MilkHistoryView());
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.grass_rounded,
                      title: 'menu_feeding'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'add_feed_sub_type'.tr,
                          icon: Icons.tune_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.FEED_SETTINGS);
                          },
                        ),
                        _drawerSubTile(
                          title: 'add_diet_plan'.tr,
                          icon: Icons.restaurant_menu_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.DIET_PLAN);
                          },
                        ),
                        _drawerSubTile(
                          title: 'feed_subtype_list'.tr,
                          icon: Icons.format_list_bulleted_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.FEED_SETTINGS_LIST);
                          },
                        ),
                        _drawerSubTile(
                          title: 'diet_plan_list'.tr,
                          icon: Icons.view_list_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.DIET_PLAN_LIST);
                          },
                        ),
                        _drawerSubTile(
                          title: 'feeding_record'.tr,
                          icon: Icons.grass_rounded,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(
                              const FeedingHistoryView(
                                initialTab: 0,
                                showTabs: false,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.storefront_outlined,
                      title: 'menu_dairy'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'add_dairy'.tr,
                          icon: Icons.storefront_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.DAIRY);
                          },
                        ),
                        _drawerSubTile(
                          title: 'dairy_list'.tr,
                          icon: Icons.list_alt_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.DAIRY_LIST);
                          },
                        ),
                        _drawerSubTile(
                          title: 'dairy_payment'.tr,
                          icon: Icons.payments_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.PAYMENT);
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.assessment_outlined,
                      title: 'menu_report'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'livestock_report'.tr,
                          icon: Icons.summarize_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.LIVESTOCK_REPORT);
                          },
                        ),
                        _drawerSubTile(
                          title: 'profit_loss'.tr,
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerRoute(Routes.PROFIT_LOSS);
                          },
                        ),
                      ],
                    ),
                    _drawerGroup(
                      icon: Icons.health_and_safety_outlined,
                      title: 'health'.tr,
                      children: [
                        _drawerSubTile(
                          title: 'dmi'.tr,
                          icon: Icons.monitor_weight_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(
                              const HealthView(initialSection: HealthSection.dmi),
                            );
                          },
                        ),
                        _drawerSubTile(
                          title: 'mastitis'.tr,
                          icon: Icons.healing_outlined,
                          onTap: () {
                            Get.back();
                            controller.openDrawerPage(
                              const HealthView(initialSection: HealthSection.mastitis),
                            );
                          },
                        ),
                      ],
                    ),
                    // _drawerTile(
                    //   icon: Icons.receipt_long_outlined,
                    //   title: 'my_orders'.tr,
                    //   onTap: () {
                    //     Get.back();
                    //     controller.openDrawerPage(const MyOrdersView());
                    //   },
                    // ),
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
                      title: 'fetch_location'.tr,
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
        final farmerPhoto = homeController.farmerPhoto.value.trim();
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
                child: ClipOval(
                  child: farmerPhoto.isNotEmpty
                      ? Image.network(
                          farmerPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
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

  Widget _drawerGroup({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(left: 16, right: 10, bottom: 4),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.primary,
      shape: const Border(),
      collapsedShape: const Border(),
      children: children,
    );
  }

  Widget _drawerSubTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.only(left: 22, right: 8),
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5),
      ),
      onTap: onTap,
    );
  }

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
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.grey,
                size: 20,
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
