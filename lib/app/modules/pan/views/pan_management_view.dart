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
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.mode == PanManagementMode.manage
                  ? 'PAN List'
                  : 'Create PAN',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.refreshAll,
              icon: const Icon(Icons.refresh_rounded),
              color: Colors.white,
            ),
          ),
        ],
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
      () => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: controller.panNameController,
              decoration: InputDecoration(
                labelText: 'PAN Name',
                hintText: 'Enter PAN/Group name',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _milkShiftSelector(
              selected: controller.selectedMilkShifts,
              onToggle: controller.toggleMilkShift,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Select Animals',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  'Selected: ${controller.selectedAnimalIds.length}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: controller.isLoadingAnimals.value
                ? const Center(child: CircularProgressIndicator())
                : controller.animals.isEmpty
                ? const Center(
                    child: Text(
                      'No animals found.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: controller.animals.length,
                    itemBuilder: (context, index) {
                      final item = controller.animals[index];
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
                            'Type: ${item.animalTypeName.isEmpty ? '-' : item.animalTypeName}\n'
                            'Tag: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}'
                            '${item.panName.trim().isEmpty ? '' : '  |  Current PAN: ${item.panName}'}',
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
                label: const Text(
                  'Create PAN',
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
    );
  }

  Widget _managePanTab() {
    return Obx(() {
      if (controller.isLoadingPans.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.pans.isEmpty) {
        return const Center(
          child: Text(
            'No PAN created yet.',
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
                      '${pan.animals.length} animals',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _milkShiftChips(pan.milkShifts),
                const SizedBox(height: 10),
                if (pan.animals.isEmpty)
                  Text(
                    'No animals in this PAN.',
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
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit PAN'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openTransferSheet(pan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Transfer',
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
    final nameController = TextEditingController(text: pan.name);
    final selectedIds = pan.animals.map((item) => item.id).toList();
    final selectedMilkShifts = pan.milkShifts.toList();

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
                  const Text(
                    'Edit PAN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'PAN Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Milk Shifts',
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
                  const SizedBox(height: 12),
                  const Text(
                    'Select Animals',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.animals.length,
                      itemBuilder: (context, index) {
                        final item = controller.animals[index];
                        final selected = selectedIds.contains(item.id);
                        return CheckboxListTile(
                          value: selected,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.animalName.isEmpty ? '-' : item.animalName,
                          ),
                          subtitle: Text(
                            'Type: ${item.animalTypeName.isEmpty ? '-' : item.animalTypeName}\n'
                            'Tag: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}',
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
                          name: nameController.text.trim(),
                          animalIds: selectedIds,
                          milkShifts: selectedMilkShifts,
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Update PAN',
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

    nameController.dispose();
  }

  Future<void> _openTransferSheet(PanGroupItem sourcePan) async {
    if (sourcePan.animals.isEmpty) {
      Get.snackbar('Info', 'No animals available in this PAN for transfer.');
      return;
    }

    final destinationPans = controller.pans
        .where((item) => item.id != sourcePan.id)
        .toList();
    if (destinationPans.isEmpty) {
      Get.snackbar('Info', 'Please create another PAN first.');
      return;
    }

    int? selectedAnimalId = sourcePan.animals.first.id;
    int? selectedToPanId = destinationPans.first.id;

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
                    'Transfer Animal from ${sourcePan.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedAnimalId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Animal',
                      border: OutlineInputBorder(),
                    ),
                    items: sourcePan.animals
                        .map(
                          (animal) => DropdownMenuItem<int>(
                            value: animal.id,
                            child: Text(
                              '${animal.animalName.isEmpty ? '-' : animal.animalName} (${animal.tagNumber.isEmpty ? '-' : animal.tagNumber})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedAnimalId = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedToPanId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Transfer To PAN',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedAnimalId == null ||
                            selectedToPanId == null) {
                          Get.snackbar(
                            'Error',
                            'Please select animal and destination PAN.',
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
                      child: const Text(
                        'Transfer Animal',
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
            const Text(
              'Milk Shifts for this PAN',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

  Widget _milkShiftChips(List<String> shifts) {
    final visible = shifts.isEmpty
        ? PanManagementController.milkShiftOptions
        : shifts;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible
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
