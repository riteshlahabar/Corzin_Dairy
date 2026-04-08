import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/doctor/controllers/doctor_controller.dart';
import '../../modules/doctor/views/doctor_view.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/shop/controllers/shop_controller.dart';
import '../../modules/shop/views/shop_view.dart';
import '../../routes/app_pages.dart';
import '../services/session_service.dart';
import '../theme/colors.dart';

class BottomNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index == 2) return;
    currentIndex.value = index;
  }

  void openAddAction() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(height: 4, width: 54, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(12)))),
            Text('quick_add'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('quick_add_desc'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700)),
            const SizedBox(height: 18),
            _sheetAction(icon: Icons.local_drink_rounded, title: 'add_milk'.tr, onTap: () { Get.back(); Get.toNamed(Routes.MILK); }),
            const SizedBox(height: 12),
            _sheetAction(icon: Icons.grass_rounded, title: 'add_feeding'.tr, onTap: () { Get.back(); Get.toNamed(Routes.FEEDING); }),
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

  Widget _sheetAction({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [Container(height: 44, width: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))), const Icon(Icons.arrow_forward_ios_rounded, size: 16)]),
      ),
    );
  }
}

class MainBottomNavView extends StatelessWidget {
  const MainBottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavController controller = Get.put(BottomNavController());
    if (!Get.isRegistered<HomeController>()) Get.put(HomeController());
    if (!Get.isRegistered<DoctorController>()) Get.put(DoctorController());
    if (!Get.isRegistered<ShopController>()) Get.put(ShopController());
    if (!Get.isRegistered<ProfileController>()) Get.put(ProfileController());

    final List<Widget> pages = [const HomeView(), const DoctorView(), const SizedBox(), const ShopView(), const ProfileView()];

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      drawer: _buildDrawer(controller),
      body: Obx(() => IndexedStack(index: controller.currentIndex.value, children: pages)),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, elevation: 1, onPressed: controller.openAddAction, child: const Icon(Icons.add, color: Colors.white)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(() => BottomAppBar(shape: const CircularNotchedRectangle(), notchMargin: 8, color: AppColors.white, elevation: 10, child: SizedBox(height: 72, child: Row(children: [_navItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'home'.tr, isSelected: controller.currentIndex.value == 0, onTap: () => controller.changeTab(0)), _navItem(icon: Icons.medical_services_outlined, selectedIcon: Icons.medical_services_rounded, label: 'doctor'.tr, isSelected: controller.currentIndex.value == 1, onTap: () => controller.changeTab(1)), const SizedBox(width: 44), _navItem(icon: Icons.storefront_outlined, selectedIcon: Icons.storefront_rounded, label: 'shop'.tr, isSelected: controller.currentIndex.value == 3, onTap: () => controller.changeTab(3)), _navItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'profile'.tr, isSelected: controller.currentIndex.value == 4, onTap: () => controller.changeTab(4))])))),
    );
  }

  Widget _buildDrawer(BottomNavController controller) {
    final homeController = Get.find<HomeController>();
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: SafeArea(
        child: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 20, 20, 18), color: AppColors.primary, child: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 54, width: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle), child: const Icon(Icons.person_outline_rounded, color: Colors.white)), const SizedBox(height: 12), Text(homeController.farmerName.value.trim().isEmpty ? 'guest'.tr : homeController.farmerName.value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('drawer_quick_access'.tr, style: const TextStyle(color: Colors.white, fontSize: 13))]))), Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [_drawerTile(icon: Icons.add_circle_outline_rounded, title: 'add_animal'.tr, onTap: () { Get.back(); Get.toNamed(Routes.ANIMAL); }), _drawerTile(icon: Icons.manage_accounts_outlined, title: 'manage_animal'.tr, onTap: () { Get.back(); Get.toNamed(Routes.MANAGE_ANIMAL); }), _drawerTile(icon: Icons.pregnant_woman_outlined, title: 'manage_pregnancy'.tr, onTap: () { Get.back(); Get.toNamed(Routes.MANAGE_PREGNANCY); }), _drawerTile(icon: Icons.child_care_outlined, title: 'add_new_born_cows'.tr, onTap: () { Get.back(); Get.toNamed(Routes.ANIMAL, arguments: {'prefillAnimalTypeName': 'Calf', 'title': 'add_new_born_cow'.tr}); }), _drawerTile(icon: Icons.history_rounded, title: 'animal_history'.tr, onTap: () { Get.back(); Get.toNamed(Routes.ANIMAL_HISTORY); }), _drawerTile(icon: Icons.health_and_safety_outlined, title: 'health'.tr, onTap: () { Get.back(); Get.toNamed(Routes.HEALTH); }), _drawerTile(icon: Icons.translate_rounded, title: 'change_language'.tr, onTap: () { Get.back(); Get.toNamed(Routes.LANGUAGE, arguments: {'fromDrawer': true}); }), _drawerTile(icon: Icons.storefront_outlined, title: 'add_dairy'.tr, onTap: () { Get.back(); Get.toNamed(Routes.DAIRY); }), _drawerTile(icon: Icons.payments_outlined, title: 'payments'.tr, onTap: () { Get.back(); Get.toNamed(Routes.PAYMENT); }), _drawerTile(icon: Icons.workspace_premium_outlined, title: 'upgrade_plan'.tr, onTap: () { Get.back(); Get.toNamed(Routes.UPGRADE); })])), Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: controller.logout, style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), icon: const Icon(Icons.logout_rounded, color: Colors.white), label: Text('logout'.tr, style: const TextStyle(color: Colors.white)))))]),
      ),
    );
  }

  Widget _drawerTile({required IconData icon, required String title, required VoidCallback onTap}) => ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title), onTap: onTap);

  Widget _navItem({required IconData icon, required IconData selectedIcon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(child: InkWell(onTap: onTap, child: SizedBox(height: 72, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppColors.primary : AppColors.grey), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.grey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))]))));
  }
}

