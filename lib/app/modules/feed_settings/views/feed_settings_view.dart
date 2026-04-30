import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/feed_settings_controller.dart';

class FeedSettingsView extends GetView<FeedSettingsController> {
  const FeedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        title: const Text('Feed Type Settings'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Feed Type'),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.fetchFeedTypes,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    if (controller.feedTypes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('No feed types found. Add your first feed type.'),
                      ),
                    ...controller.feedTypes.map((type) => _typeCard(type, context)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _typeCard(FeedTypeSettingModel type, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  type.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _openForm(context, existing: type),
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Unit: ${type.defaultUnit}',
            style: TextStyle(
              color: AppColors.grey.shade700,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: type.subtypes
                .map(
                  (subtype) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtype.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    FeedTypeSettingModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final unitController = TextEditingController(text: existing?.defaultUnit ?? 'Kg');
    final subtypeController = TextEditingController();
    final subtypes = <String>[
      ...?existing?.subtypes.map((item) => item.name.trim()).where((value) => value.isNotEmpty),
    ].obs;

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          void addSubtype() {
            final value = subtypeController.text.trim();
            if (value.isEmpty) return;
            final exists = subtypes.any((item) => item.toLowerCase() == value.toLowerCase());
            if (exists) {
              Get.snackbar('Error', 'Subtype already added');
              return;
            }
            subtypes.add(value);
            subtypeController.clear();
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null ? 'Add Feed Type' : 'Edit Feed Type',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: _input('Feed Type *'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter feed type' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: unitController,
                        decoration: _input('Unit * (dynamic)'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter unit' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: subtypeController,
                              decoration: _input('Subtype name'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: addSubtype,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Add', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subtypes
                              .map(
                                (name) => Container(
                                  padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => subtypes.remove(name),
                                        child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    if (subtypes.isEmpty) {
                                      Get.snackbar('Error', 'Please add at least one subtype');
                                      return;
                                    }
                                    final success = await controller.saveFeedType(
                                      feedTypeId: existing?.id,
                                      name: nameController.text,
                                      defaultUnit: unitController.text,
                                      subtypes: subtypes.toList(),
                                    );
                                    if (success) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        existing == null ? 'Feed type added' : 'Feed type updated',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: controller.isSaving.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(
                                    existing == null ? 'Save Feed Type' : 'Update Feed Type',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );

    nameController.dispose();
    unitController.dispose();
    subtypeController.dispose();
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
}
