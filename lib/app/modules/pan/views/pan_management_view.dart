import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/pan_management_controller.dart';

enum PanManagementMode { create, manage }

class PanManagementView extends StatefulWidget {
  const PanManagementView({super.key, this.mode = PanManagementMode.create});

  final PanManagementMode mode;

  @override
  State<PanManagementView> createState() => _PanManagementViewState();
}

class _PanManagementViewState extends State<PanManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PanManagementController controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.mode == PanManagementMode.manage ? 1 : 0,
    );
    controller = Get.put(PanManagementController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (Get.isRegistered<PanManagementController>()) {
      Get.delete<PanManagementController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: widget.mode == PanManagementMode.manage
                  ? _managePanTab()
                  : _createPanTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        6,
      ),
      child: Row(
        children: [
          _plainHeaderIcon(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _goBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.mode == PanManagementMode.manage
                  ? 'pan_list'.tr
                  : 'create_pan'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _plainHeaderIcon({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Icon(
          icon,
          color: onTap == null ? Colors.white54 : Colors.white,
        ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _createPanTab() {
    return Obx(
      () => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _requiredLabel('pan_name'.tr),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.panNameController,
                    decoration: InputDecoration(
                      hintText: 'enter_pan_group_name'.tr,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAN Type',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _panTypeSelector(
                      label: 'Milking PAN',
                      selected: controller.selectedPanType.value ==
                          PanManagementController.panTypeMilking,
                      onTap: () => controller.setPanType(
                        PanManagementController.panTypeMilking,
                      ),
                    ),
                    _panTypeSelector(
                      label: 'Non-Milking PAN',
                      selected: controller.selectedPanType.value ==
                          PanManagementController.panTypeNonMilking,
                      onTap: () => controller.setPanType(
                        PanManagementController.panTypeNonMilking,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (controller.isMilkingPan)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _milkShiftSelector(
                selected: controller.selectedMilkShifts,
                onToggle: controller.toggleMilkShift,
                requiredField: true,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      children: [
                        TextSpan(text: 'select_animals'.tr),
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${'selected'.tr}: ${controller.selectedAnimalIds.length}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            controller.isLoadingAnimals.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : controller.filteredAnimals.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        controller.isMilkingPan
                            ? 'No milking cows found.'
                            : 'no_animals_found'.tr,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: controller.filteredAnimals.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredAnimals[index];
                      final isChecked = controller.selectedAnimalIds.contains(
                        item.id,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (_) =>
                              controller.toggleAnimalSelection(item.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            item.animalName.isEmpty ? '-' : item.animalName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${'type'.tr}: ${item.animalTypeName.isEmpty ? '-' : item.animalTypeName}\n'
                            '${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}'
                            '${item.panName.trim().isEmpty ? '' : '  |  ${'current_pan'.tr}: ${item.panName}'}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          secondary: _animalImage(item.image),
                        ),
                      );
                    },
                  ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.createPan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    'create_pan'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _managePanTab() {
    return Obx(() {
      if (controller.isLoadingPans.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.pans.isEmpty) {
        return Center(
          child: Text(
            'no_pan_created_yet'.tr,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        itemCount: controller.pans.length,
        itemBuilder: (context, index) {
          final pan = controller.pans[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pan.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${pan.animals.length} ${'animals'.tr}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pan.panType == PanManagementController.panTypeMilking) ...[
                  _milkShiftChips(pan.milkShifts),
                  const SizedBox(height: 10),
                ],
                if (pan.animals.isEmpty)
                  Text(
                    'no_animals_in_pan'.tr,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pan.animals
                        .map(
                          (animal) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${animal.animalName.isEmpty ? '-' : animal.animalName} (${animal.tagNumber.isEmpty ? '-' : animal.tagNumber})',
                              style: const TextStyle(
                                fontSize: 12.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditPanSheet(pan),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('edit_pan'.tr),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openTransferSheet(pan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'transfer'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _openEditPanSheet(PanGroupItem pan) async {
    var panName = pan.name;
    final selectedIds = pan.animals.map((item) => item.id).toList();
    final editableAnimals = controller.editableAnimalsForPan(pan);
    final editableIds = editableAnimals.map((item) => item.id).toSet();
    selectedIds.removeWhere((id) => !editableIds.contains(id));
    final selectedMilkShifts = pan.milkShifts.toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      backgroundColor: const Color(0xFFF2FAF2),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 54,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(
                    'edit_pan'.tr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: panName,
                    onChanged: (value) => panName = value,
                    decoration: InputDecoration(
                      labelText: 'pan_name'.tr,
                      filled: true,
                      fillColor: const Color(0xFFF7FCF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.22)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  if (pan.panType == PanManagementController.panTypeMilking) ...[
                    const SizedBox(height: 12),
                    Text(
                      'milk_shifts'.tr,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PanManagementController.milkShiftOptions.map((
                        shift,
                      ) {
                        final selected = selectedMilkShifts.contains(shift);
                        return FilterChip(
                          selected: selected,
                          label: Text(shift),
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.14,
                          ),
                          checkmarkColor: AppColors.primary,
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                if (selectedMilkShifts.length == 1) return;
                                selectedMilkShifts.remove(shift);
                              } else {
                                selectedMilkShifts.add(shift);
                                selectedMilkShifts.sort(
                                  (a, b) => PanManagementController
                                      .milkShiftOptions
                                      .indexOf(a)
                                      .compareTo(
                                        PanManagementController.milkShiftOptions
                                            .indexOf(b),
                                      ),
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'select_animals'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: editableAnimals.length,
                      itemBuilder: (context, index) {
                        final item = editableAnimals[index];
                        final selected = selectedIds.contains(item.id);
                        return CheckboxListTile(
                          value: selected,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.animalName.isEmpty ? '-' : item.animalName,
                          ),
                          subtitle: Text(
                            '${'type'.tr}: ${item.animalTypeName.isEmpty ? '-' : item.animalTypeName}\n'
                            '${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}',
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                selectedIds.remove(item.id);
                              } else {
                                selectedIds.add(item.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await controller.updatePan(
                          panId: pan.id,
                          name: panName.trim(),
                          animalIds: selectedIds,
                          panType: pan.panType,
                          milkShifts: selectedMilkShifts,
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'update_pan'.tr,
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
        );
      },
    );
  }

  Future<void> _openTransferSheet(PanGroupItem sourcePan) async {
    final sourceAnimals = sourcePan.panType ==
            PanManagementController.panTypeMilking
        ? sourcePan.animals
            .where((animal) => animal.isMilkingAnimal)
            .toList()
        : sourcePan.animals;

    if (sourceAnimals.isEmpty) {
      Get.snackbar('info'.tr, 'no_animals_available_for_transfer'.tr);
      return;
    }

    List<PanGroupItem> destinationPansForAnimal(PanAnimalItem animal) {
      return controller.pans.where((item) {
        if (item.id == sourcePan.id) return false;
        if (item.panType == PanManagementController.panTypeMilking &&
            !animal.isMilkingAnimal) {
          return false;
        }
        return true;
      }).toList();
    }

    int? selectedAnimalId = sourceAnimals.first.id;
    final initialDestinationPans = destinationPansForAnimal(sourceAnimals.first);
    int? selectedToPanId =
        initialDestinationPans.isNotEmpty ? initialDestinationPans.first.id : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'transfer_animal_from'.tr} ${sourcePan.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (_) {
                      PanAnimalItem selectedAnimal = sourceAnimals.first;
                      for (final animal in sourceAnimals) {
                        if (animal.id == selectedAnimalId) {
                          selectedAnimal = animal;
                          break;
                        }
                      }

                      final destinationPans =
                          destinationPansForAnimal(selectedAnimal);
                      if (!destinationPans
                          .any((item) => item.id == selectedToPanId)) {
                        selectedToPanId =
                            destinationPans.isNotEmpty ? destinationPans.first.id : null;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedAnimalId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'select_animal'.tr,
                              filled: true,
                              fillColor: const Color(0xFFF7FCF7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: sourceAnimals
                                .map(
                                  (animal) => DropdownMenuItem<int>(
                                    value: animal.id,
                                    child: Text(
                                      '${animal.animalName.isEmpty ? '-' : animal.animalName} (${animal.tagNumber.isEmpty ? '-' : animal.tagNumber})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAnimalId = value;
                                if (value == null) {
                                  selectedToPanId = null;
                                  return;
                                }
                                final selected = sourceAnimals.firstWhere(
                                  (animal) => animal.id == value,
                                );
                                final allowed =
                                    destinationPansForAnimal(selected);
                                if (!allowed.any(
                                  (item) => item.id == selectedToPanId,
                                )) {
                                  selectedToPanId =
                                      allowed.isNotEmpty ? allowed.first.id : null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (destinationPans.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FCF7),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'No compatible destination PAN for selected animal.',
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              initialValue: selectedToPanId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'transfer_to_pan'.tr,
                                filled: true,
                                fillColor: const Color(0xFFF7FCF7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: destinationPans
                                  .map(
                                    (pan) => DropdownMenuItem<int>(
                                      value: pan.id,
                                      child: Text(pan.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => selectedToPanId = value),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedAnimalId == null ||
                            selectedToPanId == null) {
                          Get.snackbar(
                            'error'.tr,
                            'please_select_animal_destination_pan'.tr,
                          );
                          return;
                        }
                        final ok = await controller.transferAnimalToPan(
                          animalId: selectedAnimalId!,
                          toPanId: selectedToPanId!,
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'transfer_animal'.tr,
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
        );
      },
    );
  }

  Widget _milkShiftSelector({
    required RxList<String> selected,
    required void Function(String shift) onToggle,
    bool requiredField = false,
  }) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                children: [
                  TextSpan(text: 'milk_shifts_for_pan'.tr),
                  if (requiredField)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.primary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PanManagementController.milkShiftOptions.map((shift) {
                final isChecked = selected.contains(shift);
                return FilterChip(
                  selected: isChecked,
                  label: Text(shift),
                  selectedColor: AppColors.primary.withValues(alpha: 0.14),
                  checkmarkColor: AppColors.primary,
                  onSelected: (_) => onToggle(shift),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panTypeSelector({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade500,
                  width: selected ? 2.5 : 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _milkShiftChips(List<String> shifts) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shifts
          .map(
            (shift) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shift,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _requiredLabel(String title) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        children: [
          TextSpan(text: title),
          const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _animalImage(String source) {
    if (source.trim().isEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.pets_rounded, color: AppColors.primary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        source,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.pets_rounded, color: AppColors.primary),
        ),
      ),
    );
  }
}
