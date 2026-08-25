part of 'diet_plan_controller.dart';

extension DietPlanSubmitLogic on DietPlanController {
  Future<void> savePlan() async {
    if (!formKey.currentState!.validate()) return;
    final resolvedAnimal = _resolvedAnimalForPlan();
    if (resolvedAnimal == null) {
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr);
      return;
    }
    if (dietPlanNameController.text.trim().isEmpty) {
      dietPlanNameFocus.requestFocus();
      Get.snackbar('error'.tr, 'diet_plan_name_required'.tr);
      return;
    }

    final pan = selectedPan.value;
    if (pan != null && !resolvedAnimal.belongsToPan(pan)) {
      Get.snackbar('error'.tr, 'pan_not_match_animal'.tr);
      return;
    }

    final blocks = feedBlocks.toList();
    for (final block in blocks) {
      if (block.selectedFeedType == null) {
        Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
        return;
      }
      final subtypeValidationMessage = block.validateSelectedSubtypeInputs();
      if (subtypeValidationMessage != null) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar('error'.tr, '$feedName: $subtypeValidationMessage');
        return;
      }
      if (block.selectedSubtypePayload().isEmpty) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar(
          'error'.tr,
          'please_add_subtype_for_feed'.trParams({'feed': feedName}),
        );
        return;
      }
    }

    try {
      isSaving.value = true;
      final combinedSubtypePayload = _payloadService.collectSubtypePayload(
        blocks,
      );
      if (combinedSubtypePayload.isEmpty) {
        Get.snackbar(
          'error'.tr,
          'please_add_subtype_for_feed'.trParams({'feed': '-'}),
        );
        return;
      }

      final primaryType = blocks
          .firstWhere(
            (block) => block.selectedFeedType != null,
            orElse: () => blocks.first,
          )
          .selectedFeedType;
      if (primaryType == null) {
        Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
        return;
      }

      final result = await _repository.savePlan({
        'farmer_id': farmerId.toString(),
        'animal_id': resolvedAnimal.id.toString(),
        if (selectedPan.value != null && selectedPan.value!.id > 0)
          'pan_id': selectedPan.value!.id.toString(),
        'reference_date': selectedReferenceDateApi,
        'diet_plan_name': dietPlanNameController.text.trim(),
        // Keep compatibility with existing backend schema while sending
        // merged subtype payload for one-plan creation.
        'feed_type_id': primaryType.id.toString(),
        'unit': primaryType.defaultUnit,
        'subtype_details': combinedSubtypePayload,
      });

      final data = result.data;
      if (result.isSuccess) {
        await fetchPlans(forceRefresh: true);
        _clearForm();
        final message = data is Map ? data['message']?.toString() : null;
        final successMessage = (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'diet_plan_saved'.tr;
        _goToHomeAfterSave();
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar('success'.tr, successMessage);
        });
        return;
      }

      Get.snackbar(
        'error'.tr,
        _responseService.extractMessage(data) ?? 'unable_save_diet_plan'.tr,
      );
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveEditedPlan() async {
    if (editingPlanId <= 0) return;
    if (!formKey.currentState!.validate()) return;

    final resolvedAnimal = _resolvedAnimalForPlan();
    if (resolvedAnimal == null) {
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr);
      return;
    }

    final pan = selectedPan.value;
    if (pan != null && !resolvedAnimal.belongsToPan(pan)) {
      Get.snackbar('error'.tr, 'pan_not_match_animal'.tr);
      return;
    }

    final blocks = feedBlocks.toList();
    for (final block in blocks) {
      if (block.selectedFeedType == null) {
        Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
        return;
      }
      final subtypeValidationMessage = block.validateSelectedSubtypeInputs();
      if (subtypeValidationMessage != null) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar('error'.tr, '$feedName: $subtypeValidationMessage');
        return;
      }
      if (block.selectedSubtypePayload().isEmpty) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar(
          'error'.tr,
          'please_add_subtype_for_feed'.trParams({'feed': feedName}),
        );
        return;
      }
    }

    final nextSubtypes = _payloadService.collectSubtypePayload(blocks);
    if (nextSubtypes.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_add_subtype_for_feed'.trParams({'feed': '-'}),
      );
      return;
    }

    final primaryType = blocks
        .firstWhere(
          (block) => block.selectedFeedType != null,
          orElse: () => blocks.first,
        )
        .selectedFeedType;
    if (primaryType == null) {
      Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
      return;
    }

    final ok = await updatePlan(
      planId: editingPlanId,
      panId: selectedPan.value != null && selectedPan.value!.id > 0
          ? selectedPan.value!.id
          : null,
      referenceDate: selectedReferenceDateApi,
      feedTypeId: primaryType.id,
      unit: primaryType.defaultUnit,
      subtypeDetails: nextSubtypes,
    );
    if (ok) {
      _lastListRefreshAt = null;
      clearEditContext();
      _clearForm();
      Get.back(result: true);
      Get.snackbar('success'.tr, 'diet_plan_updated_success'.tr);
    }
  }

  void _goToHomeAfterSave() {
    if (Get.isRegistered<BottomNavController>()) {
      final nav = Get.find<BottomNavController>();
      nav.activeDrawerPage.value = null;
      nav.changeTab(0);
      nav.resetTabHistory();
      nav.runSilentSyncNow();
      return;
    }
    Get.offAllNamed(Routes.HOME);
  }

  Future<bool> updatePlan({
    required int planId,
    int? daysCount,
    int? panId,
    String? referenceDate,
    int? feedTypeId,
    String? unit,
    required List<Map<String, dynamic>> subtypeDetails,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (planId <= 0 || subtypeDetails.isEmpty) {
      Get.snackbar('error'.tr, 'invalid_diet_plan_update_payload'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final payload = <String, dynamic>{
        'farmer_id': farmerId.toString(),
        'subtype_details': subtypeDetails,
      };
      if (panId != null && panId > 0) {
        payload['pan_id'] = panId.toString();
      }
      if (referenceDate != null && referenceDate.trim().isNotEmpty) {
        payload['reference_date'] = referenceDate.trim();
      }
      if (feedTypeId != null && feedTypeId > 0) {
        payload['feed_type_id'] = feedTypeId.toString();
      }
      if (unit != null && unit.trim().isNotEmpty) {
        payload['unit'] = unit.trim();
      }
      if (daysCount != null && daysCount > 0) {
        payload['days_count'] = daysCount.toString();
      }
      final result = await _repository.updatePlan(
        planId: planId,
        payload: payload,
      );
      final data = result.data;
      if (result.isSuccess) {
        return true;
      }
      Get.snackbar(
        'error'.tr,
        _responseService.extractMessage(data) ?? 'unable_update_diet_plan'.tr,
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deletePlan({required int planId}) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (planId <= 0) {
      Get.snackbar('error'.tr, 'invalid_diet_plan_id'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final result = await _repository.deletePlan(
        planId: planId,
        farmerId: farmerId,
      );
      final data = result.data;
      if (result.isSuccess) {
        await fetchPlans(forceRefresh: true);
        return true;
      }
      Get.snackbar(
        'error'.tr,
        _responseService.extractMessage(data) ?? 'unable_delete_diet_plan'.tr,
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
