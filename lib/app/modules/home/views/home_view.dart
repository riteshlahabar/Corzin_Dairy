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
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 12),
                  _buildPlanCard(),
                  _buildMySellingAnimalsSection(),
                  const SizedBox(height: 5),
                  Obx(() => GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.25,
                    children: [
                      _statCard(title: 'today_milk'.tr, value: controller.stats['today_milk'] ?? '0', icon: Icons.water_drop_outlined, color: const Color(0xFF8B6F3D), background: const Color(0xFFFFF7E6)),
                      _statCard(title: 'total_milk'.tr, value: controller.stats['total_milk'] ?? '0', icon: Icons.local_drink_rounded, color: const Color(0xFF7A5E2D), background: const Color(0xFFFFFAEF)),
                      _statCard(title: 'today_feeding'.tr, value: controller.stats['today_feeding'] ?? '0', icon: Icons.inventory_2_outlined, color: const Color(0xFF689F38), background: const Color(0xFFF0F8E8)),
                      _statCard(title: 'total_feeding'.tr, value: controller.stats['total_feeding'] ?? '0', icon: Icons.grass_rounded, color: const Color(0xFF2E7D32), background: const Color(0xFFE8F5E9)),
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
                          child: Center(child: Text('no_payments_yet'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700))),
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
                                  '${'payment_pending'.tr}: ${payment.pendingPayment}',
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
                  _sectionTitle('animals'.tr),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 6),
      child: Builder(
        builder: (context) => Row(
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_currentGreetingIcon(), color: Colors.white.withValues(alpha: 0.86), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${_currentGreeting()},',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.farmerName.value.trim().isEmpty ? 'guest'.tr : controller.farmerName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final count = controller.unreadNotificationCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _openNotificationSheet,
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: Colors.white,
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
            icon: const Icon(Icons.menu),
            color: Colors.white,
          ),
        ],
      ),
      ),
    );
  }

  String _currentGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'greeting_morning'.tr;
    if (hour < 17) return 'greeting_afternoon'.tr;
    return 'greeting_evening'.tr;
  }

  IconData _currentGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_twilight_outlined;
    return Icons.nights_stay_outlined;
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
                    Expanded(
                      child: Text(
                        'notifications'.tr,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await controller.clearNotificationHistory();
                      },
                      child: Text('clear'.tr),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Obx(() {
                if (controller.notificationHistory.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('no_notifications_yet'.tr),
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
                      final isRead = item.isRead == true;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => controller.markNotificationAsRead(item),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRead ? const Color(0xFFF4FAF4) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? const Color(0xFFE4EFE4) : const Color(0xFFFFE082),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isRead ? AppColors.black : const Color(0xFF8A6D00),
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE082),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'unread'.tr,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF8A6D00),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt.toLocal()),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                              ),
                            ],
                          ),
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
    return Obx(() {
      final adminBanners = controller.farmerBanners;
      final total = adminBanners.length;
      if (total > 0) {
        return _heroBannerCarousel(adminBanners, total);
      }
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dashboard_overview'.tr, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('dashboard_desc'.tr, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))]),
      );
    });
  }

  Widget _heroBannerCarousel(
    List<HomeAdminBannerModel> adminBanners,
    int total,
  ) {
    final index = controller.heroBannerIndex.value % total;
    final child = _adminBannerCard(adminBanners[index]);

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: KeyedSubtree(
            key: ValueKey('admin-$index'),
            child: child,
          ),
        ),
        if (total > 1)
          Positioned(
            right: 14,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, (dotIndex) {
                final selected = dotIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 14 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: selected ? 0.95 : 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _adminBannerCard(HomeAdminBannerModel banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_rounded, color: Colors.white, size: 34),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySellingAnimalsSection() {
    return Obx(() {
      final animals = controller.publicSaleAnimals;
      if (animals.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            'buy_animal'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: animals.length,
              itemBuilder: (context, index) {
                return _saleAnimalCard(
                  animals[index],
                  width: 292,
                  margin: const EdgeInsets.only(right: 12),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _saleAnimalCard(
    HomeSaleAnimalModel animal, {
    required double width,
    EdgeInsetsGeometry? margin,
  }) {
    return InkWell(
      onTap: () => Get.toNamed(Routes.BUY_ANIMAL),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 86,
                width: 86,
                color: Colors.white.withValues(alpha: 0.14),
                child: animal.image.isEmpty
                    ? const Icon(Icons.pets_rounded, color: Colors.white, size: 34)
                    : Image.network(
                        animal.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.pets_rounded, color: Colors.white, size: 34),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_salePriceText(animal.sellingPrice), style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 14.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${animal.animalName.isEmpty ? 'animal'.tr : animal.animalName} (${animal.uniqueId.trim().isEmpty ? '-' : animal.uniqueId})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${'tag'.tr}: ${animal.tagNumber.trim().isEmpty ? '-' : animal.tagNumber}  |  ${'type'.tr}: ${animal.animalTypeName.trim().isEmpty ? '-' : animal.animalTypeName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${'age'.tr}: ${animal.age.trim().isEmpty ? '-' : animal.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${'milk_production'.tr}: ${_saleMilkText(animal.dailyMilkProduction)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _saleMilkText(String value) {
    final display = value.trim();
    if (display.isEmpty || display == 'null') return '-';
    return '$display L/day';
  }

  String _salePriceText(String value) {
    final display = value.trim();
    if (display.isEmpty || display == 'null') return '-';
    return 'Rs $display';
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.name.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  plan.amount,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('current_plan'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date - ${plan.startDate}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 10.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Renew Date - ${plan.renewDate}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 10.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Expire in - ${controller.planDaysLeft.value} days',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed(Routes.UPGRADE),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'upgrade_plan'.tr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statCard({required String title, required String value, required IconData icon, required Color color, required Color background}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.82), fontWeight: FontWeight.w700)), const SizedBox(height: 4), Row(children: [Container(height: 24, width: 24, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 13)), const SizedBox(width: 6), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)))])]),
    );
  }

  Widget _paymentColumn({required String topLabel, required String topValue, required String bottomLabel, required String bottomValue}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_formatPaymentLabel(topLabel), style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.5)), const SizedBox(height: 2), Text(topValue, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)), const Spacer(), Text(_formatPaymentLabel(bottomLabel), style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.5)), const SizedBox(height: 2), Text(bottomValue, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))]);
  }

  String _formatPaymentLabel(String value) {
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
        child: Column(children: [Container(height: 4, width: 50, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))), Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))), Expanded(child: AnimalDetailsWidget(animal: Map<String, dynamic>.from(animal))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _openLifecycleSheet(Map<String, dynamic>.from(animal)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.sync_alt_rounded, color: Colors.white), label: Text('manage_lifecycle'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))]),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Center(child: Container(height: 4, width: 54, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(12)))), Text('animal_lifecycle'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('${'update_status_for'.tr} ${animal['animal_name'] ?? '-'}', style: TextStyle(fontSize: 13, color: AppColors.grey.shade700)), const SizedBox(height: 18), _lifecycleButton(label: 'mark_active'.tr, icon: Icons.check_circle_rounded, color: AppColors.primary, onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'active'); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 10), _lifecycleButton(label: 'mark_sold'.tr, icon: Icons.verified_rounded, color: const Color(0xFF1976D2), onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'sold', notes: notesController.text); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 10), _lifecycleButton(label: 'record_death'.tr, icon: Icons.warning_amber_rounded, color: Colors.red.shade600, onTap: () async { final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'death', notes: notesController.text); if (ok) { Get.back(); Get.back(); }}), const SizedBox(height: 16), Text('move_to_another_animal_type'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 10), if (selectedType != null) Obx(() => DropdownButtonFormField<AnimalTypeOption>(initialValue: selectedType.value, isExpanded: true, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FBF8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300))), items: controller.animalTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(), onChanged: (value) => selectedType.value = value!)), const SizedBox(height: 10), TextField(controller: notesController, minLines: 2, maxLines: 3, decoration: InputDecoration(hintText: 'optional_notes'.tr, filled: true, fillColor: const Color(0xFFF8FBF8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)))), const SizedBox(height: 10), _lifecycleButton(label: 'move_animal_type'.tr, icon: Icons.sync_alt_rounded, color: const Color(0xFF6A1B9A), onTap: () async { if (selectedType == null || selectedType.value.id == 0) return; final ok = await controller.updateAnimalLifecycle(animalId: animal['id'], action: 'move_type', animalTypeId: selectedType.value.id, notes: notesController.text); if (ok) { Get.back(); Get.back(); }})]),
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(notesController.dispose);
  }

  Widget _lifecycleButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Obx(() => SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: controller.isUpdatingLifecycle.value ? null : onTap, style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: controller.isUpdatingLifecycle.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))]))));
  }
}
