import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/animal_details_widget.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).viewPadding.top + 2, 16, 20),
          children: [
            _buildTopBar(),
            const SizedBox(height: 14),
            _buildHeroCard(),
            const SizedBox(height: 12),
            _buildPlanCard(),
            const SizedBox(height: 2),
            Obx(() => GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.25,
              children: [
                _statCard(title: 'today_milk'.tr, value: controller.stats['today_milk'] ?? '0', icon: Icons.water_drop_outlined),
                _statCard(title: 'today_feeding'.tr, value: controller.stats['today_feeding'] ?? '0', icon: Icons.inventory_2_outlined),
                _statCard(title: 'total_milk'.tr, value: controller.stats['total_milk'] ?? '0', icon: Icons.local_drink_rounded),
                _statCard(title: 'total_feeding'.tr, value: controller.stats['total_feeding'] ?? '0', icon: Icons.grass_rounded),
              ],
            )),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('latest_payments'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black)), Text('view_all'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Obx(() {
                if (controller.payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: Center(child: Text('No payments yet', style: TextStyle(fontSize: 13, color: AppColors.grey.shade700))),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.payments.length,
                  itemBuilder: (context, index) {
                    final payment = controller.payments[index];
                    return Container(
                      width: 285,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF3F8F52), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.dairyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _paymentColumn(
                                    topLabel: 'today_payment'.tr,
                                    topValue: payment.todayPayment,
                                    bottomLabel: 'today_milk'.tr,
                                    bottomValue: payment.todayMilk,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                                Expanded(
                                  child: _paymentColumn(
                                    topLabel: 'total_payment'.tr,
                                    topValue: payment.totalPayment,
                                    bottomLabel: 'total_milk'.tr,
                                    bottomValue: payment.totalMilk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payment Pending: ${payment.pendingPayment}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Animals'),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.animals.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                  child: Center(child: Text('no_animals_added_yet'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700))),
                );
              }
              return SizedBox(
                height: 194,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.animals.length,
                  itemBuilder: (context, index) => _animalItem(controller.animals[index]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: Obx(
              () => RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'SFPro', color: AppColors.black),
                  children: [
                    TextSpan(
                      text: '${'welcome'.tr} ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: controller.farmerName.value.trim().isEmpty ? 'guest'.tr : controller.farmerName.value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final count = controller.notificationHistory.length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _openNotificationSheet,
                  icon: const Icon(Icons.notifications_none_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _openNotificationSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await controller.clearNotificationHistory();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Obx(() {
                if (controller.notificationHistory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No notifications yet.'),
                  );
                }

                return SizedBox(
                  height: Get.height * 0.5,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: controller.notificationHistory.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = controller.notificationHistory[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3ECE3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt.toLocal()),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dashboard_overview'.tr, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('dashboard_desc'.tr, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))]),
    );
  }

  Widget _buildPlanCard() {
    return Obx(() {
      final plan = controller.currentPlan.value;
      final shouldBlink = controller.shouldBlinkPlan;
      final blinkOn = controller.planBlinkOn.value;
      final gradientColors = shouldBlink
          ? (blinkOn
              ? const [Color(0xFFD32F2F), Color(0xFFEF5350)]
              : [const Color(0xFF4A9A58), AppColors.primary.withValues(alpha: 0.92)])
          : [const Color(0xFF4A9A58), AppColors.primary.withValues(alpha: 0.92)];
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)), child: Text(plan.name.tr, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))), const Spacer(), Text('current_plan'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600))]), const SizedBox(height: 8), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(plan.amount, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${'expires_on'.tr}: ${plan.expiryDate}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11))])), const SizedBox(width: 10), SizedBox(height: 34, child: ElevatedButton(onPressed: () => Get.toNamed(Routes.UPGRADE), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text('upgrade_plan'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))))])]),
      );
    });
  }

  Widget _statCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(fontSize: 10, color: AppColors.grey.shade700, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Row(children: [Container(height: 24, width: 24, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 13)), const SizedBox(width: 6), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)))])]),
    );
  }

  Widget _paymentColumn({required String topLabel, required String topValue, required String bottomLabel, required String bottomValue}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_formatPaymentLabel(topLabel), style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.5)), const SizedBox(height: 2), Text(topValue, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)), const Spacer(), Text(_formatPaymentLabel(bottomLabel), style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.5)), const SizedBox(height: 2), Text(bottomValue, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))]);
  }

  String _formatPaymentLabel(String value) {
    if (value == 'today_payment'.tr) return 'Today Payment';
    if (value == 'total_payment'.tr) return 'Total Payment';
    return value;
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(top: 16, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)));
  }

  Widget _animalItem(dynamic animal) {
    final animalType = (animal['animal_type_name'] ?? '-').toString();
    return GestureDetector(
      onTap: () => _openAnimalDetails(animal),
      child: Container(
        width: 176,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              animalType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 84,
                width: double.infinity,
                color: const Color(0xFFF3F6F3),
                child: (animal['image'] ?? '').toString().isNotEmpty
                    ? Image.network(
                        animal['image'],
                        height: 84,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _animalImageFallback();
                        },
                        errorBuilder: (context, error, stackTrace) => _animalImageFallback(),
                      )
                    : _animalImageFallback(),
              ),
            ),
            const SizedBox(height: 6),
            Text('${'tag'.tr}: ${animal['tag_number'] ?? '-'}', style: const TextStyle(fontSize: 10.5)),
            const SizedBox(height: 2),
            Text('${'unique_id'.tr}: ${animal['unique_id'] ?? '-'}', style: TextStyle(fontSize: 10.5, color: AppColors.grey.shade700)),
            const SizedBox(height: 3),
            Text(animal['animal_name'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _animalImageFallback() {
    return Container(
      color: const Color(0xFFF3F6F3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        size: 30,
        color: AppColors.primary,
      ),
    );
  }

  void _openAnimalDetails(dynamic animal) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.92,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Color(0xFFF6FAF6), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [Container(height: 4, width: 50, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))), Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))), Expanded(child: AnimalDetailsWidget(animal: Map<String, dynamic>.from(animal))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _openLifecycleSheet(Map<String, dynamic>.from(animal)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.sync_alt_rounded, color: Colors.white), label: const Text('Manage Lifecycle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))]),
      ),
      isScrollControlled: true,
    );
  }

  void _openLifecycleSheet(Map<String, dynamic> animal) {
    final notesController = TextEditingController();
    final currentTypeId = int.tryParse('${animal['animal_type_id']}') ?? 0;
    final selectedType = controller.animalTypes.firstWhereOrNull((type) => type.id == currentTypeId)?.obs;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Center(child: Container(height: 4, width: 54, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(12)))), Text('Animal Lifecycle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('Update status for ${animal['animal_name'] ?? '-'}', style: TextStyle(fontSize: 13, color: AppColors.grey.shade700)), const SizedBox(height: 18), _lifecycleButton(label: 'Mark Active', color: AppColors.primary, onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'active'); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 10), _lifecycleButton(label: 'Mark Sold', color: const Color(0xFF1976D2), onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'sold', notes: notesController.text); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 10), _lifecycleButton(label: 'Record Death', color: Colors.red.shade600, onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'death', notes: notesController.text); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 16), const Text('Move To Another Animal Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 10), if (selectedType != null) Obx(() => DropdownButtonFormField<AnimalTypeOption>(initialValue: selectedType.value, isExpanded: true, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FBF8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300))), items: controller.animalTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(), onChanged: (value) => selectedType.value = value!)), const SizedBox(height: 10), TextField(controller: notesController, minLines: 2, maxLines: 3, decoration: InputDecoration(hintText: 'Optional notes', filled: true, fillColor: const Color(0xFFF8FBF8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)))), const SizedBox(height: 10), _lifecycleButton(label: 'Move Animal Type', color: const Color(0xFF6A1B9A), onTap: () async { if (selectedType == null || selectedType.value.id == 0) return; final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'move_type', animalTypeId: selectedType.value.id, notes: notesController.text); if (ok) { Get.back(); Get.back(); }})]),
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(notesController.dispose);
  }

  Widget _lifecycleButton({required String label, required Color color, required VoidCallback onTap}) {
    return Obx(() => SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: controller.isUpdatingLifecycle.value ? null : onTap, style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: controller.isUpdatingLifecycle.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))));
  }
}
