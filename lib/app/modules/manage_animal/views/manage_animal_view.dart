import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/manage_animal_controller.dart';

class ManageAnimalView extends GetView<ManageAnimalController> {
  const ManageAnimalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'manage_animal'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'search_animal_tag_status'.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('all', 'all'.tr),
                    _filterChip('active', 'active'.tr),
                    _filterChip('selling', 'status_selling'.tr),
                    _filterChip('sold', 'sold'.tr),
                    _filterChip('death', 'death'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchAnimals,
                        child: controller.filteredAnimals.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: 120),
                                  const Icon(
                                    Icons.manage_accounts_rounded,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_animals_found'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: controller.filteredAnimals.length,
                                itemBuilder: (context, index) {
                                  final animal =
                                      controller.filteredAnimals[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _animalImage(animal.image),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    animal.animalName.isEmpty
                                                        ? '-'
                                                        : animal.animalName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${'tag'.tr}: ${animal.tagNumber.isEmpty ? '-' : animal.tagNumber}',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors
                                                          .grey
                                                          .shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${'type'.tr}: ${animal.animalTypeName.isEmpty ? '-' : controller.translatedAnimalTypeName(animal.animalTypeName)}',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors
                                                          .grey
                                                          .shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _statusBadge(animal),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _detailRow(
                                          'unique_id'.tr,
                                          animal.uniqueId.isEmpty
                                              ? '-'
                                              : animal.uniqueId,
                                        ),
                                        _detailRow(
                                          'age'.tr,
                                          animal.age.isEmpty ? '-' : controller.translatedAge(animal.age),
                                        ),
                                        _detailRow(
                                          'birth_date'.tr,
                                          animal.birthDate.isEmpty
                                              ? '-'
                                              : animal.birthDate,
                                        ),
                                        _detailRow(
                                          'gender'.tr,
                                          animal.gender.isEmpty
                                              ? '-'
                                              : controller.translatedGender(animal.gender),
                                        ),
                                        _detailRow(
                                          'weight'.tr,
                                          animal.weight.isEmpty
                                              ? '-'
                                              : '${animal.weight} Kg',
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _openManageSheet(animal),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              'manage_animal'.tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _filterChip(String value, String label) {
    final isSelected = controller.selectedFilter.value == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.selectedFilter.value = value,
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _animalImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 74,
        width: 74,
        child: imageUrl.isEmpty
            ? _imageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imageFallback(),
              ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.pets_rounded, color: AppColors.primary, size: 30),
    );
  }

  Widget _statusBadge(ManageAnimalItem animal) {
    final value = animal.displayStatus;
    Color color = AppColors.primary;
    if (value == 'sold') {
      color = const Color(0xFF1976D2);
    } else if (value == 'selling') {
      color = const Color(0xFFB25E00);
    } else if (value == 'death') {
      color = Colors.red;
    }

    final label = value == 'selling' ? 'status_selling'.tr : (value.isEmpty ? 'active'.tr : value.toLowerCase().tr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  void _openManageSheet(ManageAnimalItem animal) {
    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          Future<void> closeLifecycleSheet() async {
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Obx(() {
              final liveAnimal = controller.animals.firstWhereOrNull(
                    (item) => item.id == animal.id,
                  ) ??
                  animal;
              final animalName = liveAnimal.animalName.isEmpty
                  ? 'Animal'
                  : liveAnimal.animalName;
              final statusMessage = _lifecycleStatusMessage(
                lifecycleStatus: liveAnimal.lifecycleStatus,
              );
              final canShowSellAction = _canShowSellAction(
                lifecycleStatus: liveAnimal.lifecycleStatus,
              );
              final canShowLifecycleActions =
                  _canShowLifecycleActions(lifecycleStatus: liveAnimal.lifecycleStatus);
              final canMarkActive = _canShowMarkActive(
                lifecycleStatus: liveAnimal.lifecycleStatus,
                isForSale: liveAnimal.isForSale,
              );

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      'animal_lifecycle'.tr,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'manage_selected_animal'.trParams({
                        'name': liveAnimal.animalName.isEmpty
                            ? 'animal'.tr
                            : liveAnimal.animalName,
                      }),
                      style:
                          TextStyle(fontSize: 13, color: AppColors.grey.shade700),
                    ),
                    const SizedBox(height: 18),
                    if (canShowSellAction)
                      _sheetButton(
                        liveAnimal.isForSale
                            ? 'cancel_selling_named'.trParams({'name': animalName})
                            : 'sell_named'.trParams({'name': animalName}),
                        const Color(0xFFB25E00),
                        liveAnimal.isForSale
                            ? () => _confirmCancelSellingAnimal(
                                  liveAnimal,
                                  onSuccess: closeLifecycleSheet,
                                )
                            : () => _confirmSellAnimal(
                                  liveAnimal,
                                  onSuccess: closeLifecycleSheet,
                                ),
                        icon: liveAnimal.isForSale
                            ? Icons.cancel_presentation_rounded
                            : Icons.storefront_rounded,
                      ),
                    if (statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                    if (canShowLifecycleActions) ...[
                      const SizedBox(height: 10),
                      if (canMarkActive) ...[
                        _sheetButton('mark_active'.tr, AppColors.primary, () async {
                          await _confirmAndHandleLifecycleAction(
                            animalId: liveAnimal.id,
                            action: 'active',
                            label: 'mark_active'.tr,
                            onSuccess: closeLifecycleSheet,
                          );
                        }, icon: Icons.check_circle_rounded),
                        const SizedBox(height: 10),
                      ],
                      _sheetButton('mark_sold'.tr, const Color(0xFF1976D2), () async {
                        await _confirmAndHandleLifecycleAction(
                          animalId: liveAnimal.id,
                          action: 'sold',
                          label: 'mark_sold'.tr,
                          onSuccess: closeLifecycleSheet,
                        );
                      }, icon: Icons.verified_rounded),
                      const SizedBox(height: 10),
                      _sheetButton('record_death'.tr, Colors.red.shade600, () async {
                        await _confirmAndHandleLifecycleAction(
                          animalId: liveAnimal.id,
                          action: 'death',
                          label: 'record_death'.tr,
                          onSuccess: closeLifecycleSheet,
                        );
                      }, icon: Icons.warning_amber_rounded),
                    ],
                  ],
                ),
              );
            }),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _confirmAndHandleLifecycleAction({
    required int animalId,
    required String action,
    required String label,
    Future<void> Function()? onSuccess,
  }) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('confirmation'.tr),
        content: Text('confirm_action'.trParams({'action': label})),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('ok'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await controller.updateAnimalLifecycle(
      animalId: animalId,
      action: action,
    );
    if (!ok) return;
    if (onSuccess != null) {
      await onSuccess();
    }
  }

  bool _canShowMarkActive({
    required String lifecycleStatus,
    required bool isForSale,
  }) {
    final normalized = lifecycleStatus.trim().toLowerCase();
    if (isForSale) return false;
    return normalized != 'active' &&
        normalized != 'sold' &&
        normalized != 'death';
  }

  bool _canShowLifecycleActions({
    required String lifecycleStatus,
  }) {
    return lifecycleStatus.trim().toLowerCase() == 'active';
  }

  String? _lifecycleStatusMessage({
    required String lifecycleStatus,
  }) {
    final normalized = lifecycleStatus.trim().toLowerCase();
    if (normalized == 'sold') {
      return 'animal_already_sold'.tr;
    }
    if (normalized == 'death') {
      return 'animal_already_dead'.tr;
    }
    return null;
  }

  bool _canShowSellAction({
    required String lifecycleStatus,
  }) {
    final normalized = lifecycleStatus.trim().toLowerCase();
    return normalized != 'sold' && normalized != 'death';
  }

  void _confirmSellAnimal(
    ManageAnimalItem animal, {
    Future<void> Function()? onSuccess,
  }) {
    final animalName = animal.animalName.isEmpty ? 'animal'.tr : animal.animalName;
    var priceText = '';
    final priceError = ''.obs;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFB25E00).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFB25E00), size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'confirm_sale_title'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'confirm_sale_message'.trParams({'name': animalName}),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.grey.shade700),
              ),
              const SizedBox(height: 14),
              Obx(
                () => TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    priceText = value;
                    if (priceError.value.isNotEmpty) {
                      priceError.value = '';
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'selling_price_rs'.tr,
                    hintText: 'enter_selling_price'.tr,
                    errorText: priceError.value.isEmpty ? null : priceError.value,
                    isDense: true,
                    prefixText: 'Rs ',
                    filled: true,
                    fillColor: const Color(0xFFF7FAF7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                final price = double.tryParse(priceText.trim());
                                if (price == null || price <= 0) {
                                  priceError.value =
                                      'enter_valid_selling_price'.tr;
                                  return;
                                }
                                FocusManager.instance.primaryFocus?.unfocus();
                                if (Get.isDialogOpen == true) {
                                  Get.back();
                                }
                                final ok = await controller.sellAnimal(
                                  animal,
                                  sellingPrice: price,
                                );
                                if (!ok) return;
                                if (onSuccess != null) {
                                  await onSuccess();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB25E00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text('sell'.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancelSellingAnimal(
    ManageAnimalItem animal, {
    Future<void> Function()? onSuccess,
  }) {
    final animalName = animal.animalName.isEmpty ? 'animal'.tr : animal.animalName;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFB25E00).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_presentation_rounded, color: Color(0xFFB25E00), size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'cancel_selling_title'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'cancel_selling_message'.trParams({'name': animalName}),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.grey.shade700),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                if (Get.isDialogOpen == true) {
                                  Get.back();
                                }
                                final ok = await controller.cancelSellingAnimal(animal);
                                if (!ok) return;
                                if (onSuccess != null) {
                                  await onSuccess();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB25E00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text('confirm'.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetButton(String label, Color color, VoidCallback? onTap, {required IconData icon}) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: controller.isSubmitting.value || onTap == null ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

}
