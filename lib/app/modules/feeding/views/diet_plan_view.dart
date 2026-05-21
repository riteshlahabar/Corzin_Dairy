import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/diet_plan_controller.dart';
import '../controllers/feeding_controller.dart';

enum DietPlanViewMode { add, list }

class DietPlanView extends StatelessWidget {
  const DietPlanView({super.key, this.mode = DietPlanViewMode.add});

  final DietPlanViewMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DietPlanController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (Get.isRegistered<BottomNavController>() &&
                Get.find<BottomNavController>().closeDrawerPage()) {
              return;
            }
            Get.back();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          mode == DietPlanViewMode.add ? 'add_diet_plan'.tr : 'diet_plan_list'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchPlans();
                  if (mode == DietPlanViewMode.add) {
                    await controller.fetchAnimals();
                    await controller.fetchFeedTypes();
                  }
                },
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 18),
                  children: [
                    if (mode == DietPlanViewMode.add) ...[
                      _formCard(controller),
                    ] else ...[
                      _plansCard(controller),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _formCard(DietPlanController controller) {
    final uniqueAnimals = <int, FeedingAnimalModel>{};
    for (final animal in controller.animals) {
      if (animal.id <= 0) continue;
      uniqueAnimals.putIfAbsent(animal.id, () => animal);
    }
    final animalItems = uniqueAnimals.values.toList();

    FeedingAnimalModel? selectedAnimalValue;
    final selectedAnimal = controller.selectedAnimal.value;
    if (selectedAnimal != null) {
      for (final animal in animalItems) {
        if (animal.id == selectedAnimal.id) {
          selectedAnimalValue = animal;
          break;
        }
      }
    }

    final uniquePans = <String, FeedingPanModel>{};
    for (final pan in controller.pans) {
      final key = pan.id > 0 ? 'id_${pan.id}' : 'name_${pan.name.trim().toLowerCase()}';
      uniquePans.putIfAbsent(key, () => pan);
    }
    final panItems = uniquePans.values.toList();

    FeedingPanModel? selectedPanValue;
    final selectedPan = controller.selectedPan.value;
    if (selectedPan != null) {
      for (final pan in panItems) {
        if (pan.matches(selectedPan)) {
          selectedPanValue = pan;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4EA857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'add_diet_plan'.tr,
                          style: const TextStyle(
                            fontSize: 14.8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'create_animal_wise_diet_plan'.tr,
                          style: TextStyle(
                            fontSize: 11.4,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FCF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0EFE1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('choose_animal'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<FeedingAnimalModel>(
                    initialValue: selectedAnimalValue,
                    isExpanded: true,
                    dropdownColor: const Color(0xFFF1FAF1),
                    decoration: _decoration('choose_animal'.tr),
                    items: animalItems
                        .map(
                          (animal) => DropdownMenuItem<FeedingAnimalModel>(
                            value: animal,
                            child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: controller.onAnimalChanged,
                    validator: (value) {
                      if (controller.selectedPan.value != null) return null;
                      return value == null ? 'select_animal_error'.tr : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _fieldLabel('select_pan'.tr, requiredField: false),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<FeedingPanModel>(
                    initialValue: selectedPanValue,
                    isExpanded: true,
                    dropdownColor: const Color(0xFFF1FAF1),
                    decoration: _decoration('select_pan'.tr),
                    items: panItems
                        .map(
                          (pan) => DropdownMenuItem<FeedingPanModel>(
                            value: pan,
                            child: Text(pan.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: controller.onPanChanged,
                  ),
                  const SizedBox(height: 10),
                  _fieldLabel('date'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.referenceDateController,
                    readOnly: true,
                    onTap: controller.pickReferenceDate,
                    decoration: _decoration('select_date'.tr),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'select_date_error'.tr : null,
                  ),
                  const SizedBox(height: 10),
                  _fieldLabel('diet_plan'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.dietPlanNameController,
                    focusNode: controller.dietPlanNameFocus,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Enter diet plan name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Diet plan name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final blocks = controller.feedBlocks;
              return Column(
                children: [
                  ...blocks.asMap().entries.map(
                    (entry) => _feedTypeBlockCard(
                      controller: controller,
                      block: entry.value,
                      index: entry.key,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: controller.addFeedBlock,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                      label: Text(
                        'add_more_feed'.tr,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
            Obx(() => _liveDmiSummaryCard(controller)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isSaving.value ? null : () => _onSavePlanTap(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'save'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveDmiSummaryCard(DietPlanController controller) {
    final planned = controller.plannedDryMatterTotal;
    final target = controller.targetDmi.value;
    final gap = controller.dmiGap.value;
    final isPositiveGap = gap >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEDDC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${'body_weight'.tr}: ${controller.bodyWeight.value.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C6B36),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${'total_milk'.tr}: ${controller.milkProduction.value.toStringAsFixed(2)} L',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C6B36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${'dry_matter'.tr}: ${planned.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${'required_dmi'.tr}: ${target.toStringAsFixed(2)} kg',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${'gap'.tr}: ${gap.toStringAsFixed(2)} kg',
              style: TextStyle(
                fontSize: 12.6,
                fontWeight: FontWeight.w800,
                color: isPositiveGap ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedTypeBlockCard({
    required DietPlanController controller,
    required DietFeedBlock block,
    required int index,
  }) {
    final availableFeedTypes = controller.availableFeedTypesForBlock(block);
    final selectedType = block.selectedFeedType;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EEE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _fieldLabel('${'select_feed_type'.tr} ${index + 1}', requiredField: true),
              ),
              if (index > 0)
                InkWell(
                  onTap: () => controller.removeFeedBlock(block),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<FeedTypeModel>(
            initialValue: selectedType,
            isExpanded: true,
            dropdownColor: const Color(0xFFF1FAF1),
            decoration: _decoration('select_feed_type'.tr),
            items: availableFeedTypes
                .map(
                  (type) => DropdownMenuItem<FeedTypeModel>(
                    value: type,
                    child: Text(type.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => controller.onFeedTypeChangedForBlock(block, value),
          ),
          if (selectedType != null) ...[
            const SizedBox(height: 10),
            _fieldLabel('${'subtype_name'.tr} (${block.unit})', requiredField: true),
            const SizedBox(height: 8),
            ...selectedType.subtypes.map(
              (subtype) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: block.subtypeSelected[subtype.id] ?? false,
                      onChanged: (value) => controller.onSubtypeToggleForBlock(
                        block,
                        subtype.id,
                        value ?? false,
                      ),
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        subtype.name,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 86,
                      child: TextField(
                        controller: block.subtypeQtyControllers[subtype.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _decoration('qty'.tr).copyWith(
                          hintText: 'qty'.tr,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 86,
                      child: TextField(
                        controller: block.subtypeDmPercentControllers[subtype.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _decoration('dm_percent'.tr).copyWith(
                          hintText: 'dm_percent'.tr,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF9F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${'total'.tr}: ${block.totalQuantity.toStringAsFixed(2)} ${block.unit}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plansCard(DietPlanController controller) {
    return Obx(() {
      final plans = controller.plans;
      if (plans.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'no_diet_plan_found'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      final totalBalance = plans.fold<double>(
        0,
        (sum, item) => sum + item.remainingQuantity,
      );
      final unit = plans.first.unit;

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF4EA857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    icon: Icons.list_alt_rounded,
                    label: 'diet_plan_list'.tr,
                    value: plans.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryTile(
                    icon: Icons.scale_rounded,
                    label: 'balance'.tr,
                    value: '${totalBalance.toStringAsFixed(2)} $unit',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...plans.asMap().entries.map(
            (entry) => _planCard(
              controller: controller,
              plan: entry.value,
              index: entry.key,
            ),
          ),
        ],
      );
    });
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.88)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required DietPlanController controller,
    required FeedDietPlanModel plan,
    required int index,
  }) {
    final stripe = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFF57C00),
      const Color(0xFF8E24AA),
    ][index % 4];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: stripe,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dietPlanTitle(plan),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _planOwnerLabel(controller, plan),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.4,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionIcon(
                      icon: Icons.edit_rounded,
                      color: AppColors.primary,
                      tooltip: 'edit'.tr,
                      onTap: () => _openEditPlanDialog(controller, plan),
                    ),
                    const SizedBox(width: 6),
                    _actionIcon(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      tooltip: 'delete'.tr,
                      onTap: () => _confirmDeletePlan(controller, plan),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoBadge(
                      icon: Icons.grass_rounded,
                      text: plan.feedType,
                      bgColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF256029),
                    ),
                    _infoBadge(
                      icon: Icons.scale_rounded,
                      text: '${'balance'.tr}: ${plan.remainingQuantity.toStringAsFixed(2)} ${plan.unit}',
                      bgColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF0D47A1),
                    ),
                    _infoBadge(
                      icon: Icons.science_rounded,
                      text: '${'dry_matter'.tr}: ${plan.planDryMatterQuantity.toStringAsFixed(2)} ${plan.unit}',
                      bgColor: const Color(0xFFF3E5F5),
                      textColor: const Color(0xFF6A1B9A),
                    ),
                    _infoBadge(
                      icon: Icons.show_chart_rounded,
                      text: '${'required_dmi'.tr}: ${plan.targetDmi.toStringAsFixed(2)}',
                      bgColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF0D47A1),
                    ),
                    _infoBadge(
                      icon: plan.dmiGap >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      text: '${'gap'.tr}: ${plan.dmiGap.toStringAsFixed(2)}',
                      bgColor: plan.dmiGap >= 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      textColor: plan.dmiGap >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (plan.subtypeDetails.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: plan.subtypeDetails
                        .map(
                          (subtype) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FAF4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD6EFD8)),
                            ),
                            child: Text(
                              '${subtype.name}: ${subtype.quantity.toStringAsFixed(2)} ${plan.unit} | DM ${subtype.dmPercent.toStringAsFixed(2)}% | ${subtype.dryMatterQuantity.toStringAsFixed(2)} ${plan.unit}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dietPlanTitle(FeedDietPlanModel plan) {
    final name = plan.dietPlanName.trim();
    if (name.isNotEmpty) return name;
    return 'diet_plan'.tr;
  }

  String _planOwnerLabel(DietPlanController controller, FeedDietPlanModel plan) {
    if (plan.panId > 0) {
      for (final pan in controller.pans) {
        if (pan.id == plan.panId) {
          final panName = pan.name.trim();
          if (panName.isNotEmpty) return panName;
          break;
        }
      }
      return 'PAN #${plan.panId}';
    }

    final animalName = plan.animalName.trim();
    final tag = plan.tagNumber.trim();
    if (tag.isEmpty) return animalName;
    return '$animalName ($tag)';
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _infoBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _fieldLabel(String title, {required bool requiredField}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          children: [
            TextSpan(text: title),
            if (requiredField)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  void _onSavePlanTap(DietPlanController controller) {
    final form = controller.formKey.currentState;
    if (form == null) return;

    final isValid = form.validate();
    if (!isValid) {
      _focusFirstInvalidField(controller);
      return;
    }

    if (controller.selectedAnimal.value == null &&
        controller.selectedPan.value == null) {
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr);
      return;
    }

    controller.savePlan();
  }

  void _focusFirstInvalidField(DietPlanController controller) {
    // Days field is temporarily removed from add form, so no focus handoff needed here.
  }

  Future<void> _openEditPlanDialog(
    DietPlanController controller,
    FeedDietPlanModel plan,
  ) async {
    final formKey = GlobalKey<FormState>();
    final qtyControllers = <int, TextEditingController>{
      for (var i = 0; i < plan.subtypeDetails.length; i++)
        i: TextEditingController(text: plan.subtypeDetails[i].quantity.toStringAsFixed(2)),
    };
    final dmControllers = <int, TextEditingController>{
      for (var i = 0; i < plan.subtypeDetails.length; i++)
        i: TextEditingController(
          text: plan.subtypeDetails[i].dmPercent > 0
              ? plan.subtypeDetails[i].dmPercent.toStringAsFixed(2)
              : '',
        ),
    };
    final editListenables = <Listenable>[
      ...qtyControllers.values,
      ...dmControllers.values,
    ];

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'edit_diet_plan_title'.tr,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${plan.animalName} (${plan.tagNumber})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.8),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: plan.subtypeDetails.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subtype = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FCF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE1EEE1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subtype.name,
                                  style: const TextStyle(
                                    fontSize: 12.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 76,
                                child: TextFormField(
                                  controller: qtyControllers[index],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 12.2),
                                  decoration: _decoration('qty'.tr).copyWith(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                  ),
                                  validator: (value) {
                                    final qty = double.tryParse((value ?? '').trim()) ?? 0;
                                    if (qty <= 0) return 'invalid'.tr;
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 76,
                                child: TextFormField(
                                  controller: dmControllers[index],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 12.2),
                                  decoration: _decoration('dm_percent'.tr).copyWith(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                  ),
                                  validator: (value) {
                                    final dm = double.tryParse((value ?? '').trim()) ?? 0;
                                    if (dm <= 0 || dm > 100) return 'invalid_dm_percent'.tr;
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: Listenable.merge(editListenables),
                  builder: (context, child) {
                    double plannedDm = 0;
                    for (final entry in plan.subtypeDetails.asMap().entries) {
                      final index = entry.key;
                      final qty = double.tryParse(qtyControllers[index]?.text.trim() ?? '') ?? 0;
                      final dm = double.tryParse(dmControllers[index]?.text.trim() ?? '') ?? 0;
                      if (qty > 0 && dm > 0 && dm <= 100) {
                        plannedDm += (qty * dm) / 100;
                      }
                    }
                    final gap = plannedDm - plan.targetDmi;
                    final gapColor = gap >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDEDDC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'dry_matter'.tr}: ${plannedDm.toStringAsFixed(2)} ${plan.unit}',
                            style: const TextStyle(
                              fontSize: 12.4,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${'required_dmi'.tr}: ${plan.targetDmi.toStringAsFixed(2)} kg',
                                  style: const TextStyle(
                                    fontSize: 12.1,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                              Text(
                                '${'gap'.tr}: ${gap.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.3,
                                  fontWeight: FontWeight.w800,
                                  color: gapColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final nextSubtypes = plan.subtypeDetails.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final subtype = entry.value;
                                    return {
                                      'subtype_id': subtype.subtypeId > 0 ? subtype.subtypeId : null,
                                      'name': subtype.name,
                                      'quantity': double.tryParse(qtyControllers[index]?.text.trim() ?? '0') ?? 0,
                                      'dm_percent': double.tryParse(dmControllers[index]?.text.trim() ?? '0') ?? 0,
                                    };
                                  }).toList();

                                  final ok = await controller.updatePlan(
                                    planId: plan.id,
                                    panId: plan.panId > 0 ? plan.panId : null,
                                    referenceDate: plan.referenceDate.trim().isNotEmpty
                                        ? plan.referenceDate.trim()
                                        : null,
                                    subtypeDetails: nextSubtypes,
                                  );
                                  if (ok) {
                                    Get.back();
                                    Get.snackbar('success'.tr, 'diet_plan_updated_success'.tr);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: controller.isSaving.value
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('save'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    for (final item in qtyControllers.values) {
      item.dispose();
    }
    for (final item in dmControllers.values) {
      item.dispose();
    }
  }

  Future<void> _confirmDeletePlan(
    DietPlanController controller,
    FeedDietPlanModel plan,
  ) async {
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'delete_diet_plan_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_diet_plan_confirm'.trParams({'name': plan.animalName}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.black.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'delete'.tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    if (confirmed != true) return;
    final ok = await controller.deletePlan(planId: plan.id);
    if (ok) {
      Get.snackbar('success'.tr, 'diet_plan_deleted_success'.tr);
    }
  }
}
