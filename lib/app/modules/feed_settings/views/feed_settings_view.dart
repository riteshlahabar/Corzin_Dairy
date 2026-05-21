import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/feed_settings_controller.dart';

enum FeedSettingsViewMode { add, list }

class FeedSettingsView extends GetView<FeedSettingsController> {
  const FeedSettingsView({super.key, this.mode = FeedSettingsViewMode.add});

  final FeedSettingsViewMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          mode == FeedSettingsViewMode.add ? 'add_feed_sub_type'.tr : 'feed_subtype_list'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: mode == FeedSettingsViewMode.list
          ? FloatingActionButton.extended(
              onPressed: _openAddSubtypeScreen,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('add_feed_sub_type'.tr),
            )
          : null,
      body: mode == FeedSettingsViewMode.add
          ? _FeedSubtypeAddForm(controller: controller, inputDecorationBuilder: _input)
          : Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: controller.fetchFeedTypes,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          _introCard(),
                          const SizedBox(height: 14),
                          if (controller.feedTypes.isEmpty) _emptyCard(),
                          ...controller.feedTypes.map(_typeCard),
                        ],
                      ),
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

  void _openAddSubtypeScreen() {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().openDrawerRoute(Routes.FEED_SETTINGS);
      return;
    }
    Get.toNamed(Routes.FEED_SETTINGS);
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4EA857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.category_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'feed_subtype_intro'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Center(
        child: Text(
          'no_feed_types_found'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _typeCard(FeedTypeSettingModel type) {
    final hasSubtype = type.subtypes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${'unit'.tr}: ${type.defaultUnit}',
                  style: TextStyle(
                    color: AppColors.grey.shade800,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasSubtype)
            Column(
              children: type.subtypes
                  .map(
                    (subtype) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtype.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'edit_subtype'.tr,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _openEditSubtypeDialog(type, subtype),
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                          ),
                          IconButton(
                            tooltip: 'delete_subtype'.tr,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteSubtype(type, subtype),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'admin_no_subtype_add_now'.tr,
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _openEditSubtypeDialog(
    FeedTypeSettingModel type,
    FeedSubtypeSettingModel subtype,
  ) async {
    final nameController = TextEditingController(text: subtype.name);

    await Get.dialog(
      AlertDialog(
        title: Text('edit_subtype_title'.tr),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: _input('subtype_name'.tr),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      final nextName = nameController.text.trim();
                      if (nextName.isEmpty) {
                        Get.snackbar('error'.tr, 'subtype_name_required'.tr);
                        return;
                      }
                      final ok = await controller.updateFeedSubtype(
                        feedTypeId: type.id,
                        subtypeId: subtype.id,
                        name: nextName,
                      );
                      if (ok) {
                        Get.back();
                        Get.snackbar('success'.tr, 'subtype_updated_success'.tr);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('save'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    nameController.dispose();
  }

  Future<void> _confirmDeleteSubtype(
    FeedTypeSettingModel type,
    FeedSubtypeSettingModel subtype,
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
                'delete_subtype_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_subtype_confirm'.trParams({'name': subtype.name}),
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

    final ok = await controller.deleteFeedSubtype(
      feedTypeId: type.id,
      subtypeId: subtype.id,
    );
    if (ok) {
      Get.snackbar('success'.tr, 'subtype_deleted_success'.tr);
    }
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

class _FeedSubtypeAddForm extends StatefulWidget {
  const _FeedSubtypeAddForm({
    required this.controller,
    required this.inputDecorationBuilder,
  });

  final FeedSettingsController controller;
  final InputDecoration Function(String hint) inputDecorationBuilder;

  @override
  State<_FeedSubtypeAddForm> createState() => _FeedSubtypeAddFormState();
}

class _FeedSubtypeAddFormState extends State<_FeedSubtypeAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _subtypeController = TextEditingController();
  final _subtypeFocus = FocusNode();
  int? _selectedTypeId;
  final List<String> _subtypes = <String>[];

  void _addSubtype() {
    final value = _subtypeController.text.trim();
    if (value.isEmpty) {
      _subtypeFocus.requestFocus();
      return;
    }
    final exists = _subtypes.any((item) => item.toLowerCase() == value.toLowerCase());
    if (exists) {
      Get.snackbar('error'.tr, 'subtype_already_added'.tr);
      return;
    }
    setState(() {
      _subtypes.add(value);
      _subtypeController.clear();
    });
    _subtypeFocus.requestFocus();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subtypes.isEmpty) {
      _subtypeFocus.requestFocus();
      Get.snackbar('error'.tr, 'please_add_one_subtype'.tr);
      return;
    }
    final typeId = _selectedTypeId;
    if (typeId == null || typeId <= 0) {
      Get.snackbar('error'.tr, 'select_feed_type_error'.tr);
      return;
    }
    final success = await widget.controller.saveFeedSubtypes(
      feedTypeId: typeId,
      subtypes: _subtypes,
    );
    if (!mounted || !success) return;
    setState(() {
      _subtypes.clear();
      _subtypeController.clear();
    });
    Get.snackbar('success'.tr, 'feed_subtype_saved'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void dispose() {
    _subtypeController.dispose();
    _subtypeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = widget.controller.feedTypes.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (_selectedTypeId != null && !items.any((item) => item.id == _selectedTypeId)) {
        _selectedTypeId = null;
      }

      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
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
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'feed_subtype_intro'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  _requiredLabel('feed_type'.tr),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTypeId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFFF4FAF4),
                    decoration: widget.inputDecorationBuilder('feed_type'.tr).copyWith(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        ),
                    items: items
                        .map((item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedTypeId = value),
                    validator: (value) => value == null || value <= 0 ? 'select_feed_type_error'.tr : null,
                  ),
                  const SizedBox(height: 10),
                  _requiredLabel('subtype_name'.tr),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtypeController,
                          focusNode: _subtypeFocus,
                          onSubmitted: (_) => _addSubtype(),
                          style: const TextStyle(fontSize: 13),
                          decoration: widget.inputDecorationBuilder('subtype_name'.tr).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _addSubtype,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: Text('add'.tr, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subtypes
                        .map((name) => Container(
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
                                    onTap: () => setState(() => _subtypes.remove(name)),
                                    child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: widget.controller.isSaving.value ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: widget.controller.isSaving.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text('save'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12.6,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
