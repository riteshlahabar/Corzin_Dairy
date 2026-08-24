part of 'health_view.dart';

Widget _buildHealthMastitisList(_HealthViewState state) {
    final records = state.controller.filteredMastitisGroups;
    return RefreshIndicator(
      onRefresh: () async {
        await state.controller.fetchMastitisRecords();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _healthMastitisSearchBar(state),
          const SizedBox(height: 10),
          _healthMastitisResultFilters(state),
          const SizedBox(height: 12),
          if (records.isEmpty)
            state._inlineEmptyState('no_mastitis_records_found'.tr)
          else
            ...records.map(
              (item) => _healthMastitisCard(state, item),
            ),
        ],
      ),
    );
  }

Widget _healthMastitisCard(_HealthViewState state, MastitisGroupItem item) {
    final treatments = item.treatments;
    final recoveredRows = item.recoveredRows;
    final isRecovered = item.recoveryStatus == 'recovered' || item.recoveryStatus == 'recoverd';
    final recoveredRow = recoveredRows.isNotEmpty ? recoveredRows.first : null;
    return state._card(
      title: '${item.animalName} - ${'tag'.tr} ${item.tagNumber}',
      subtitle: state._mastitisResultLabel(item.effectiveTestResult),
      dateLabel: 'positive_found_date'.tr,
      dateText: item.positiveFoundDate,
      status: state._mastitisStatusLabel(item.recoveryStatus),
      rows: [
        if (treatments.isEmpty)
          state._info('treatment'.tr, 'no_treatment_added'.tr)
        else
          ...treatments.map(
            (row) => state._info(row.date, row.treatment),
          ),
        if (recoveredRow != null) ...[
          const SizedBox(height: 4),
          state._info(recoveredRow.date, 'recovered'.tr),
        ],
        if (!isRecovered) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openHealthMastitisTreatmentSheet(state, state.context, item),
                  icon: const Icon(Icons.medical_services_outlined, size: 18),
                  label: Text('add_treatment'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmHealthMastitisRecovered(state, item),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text('recovered'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

Widget _healthMastitisSearchBar(_HealthViewState state) {
    return Obx(
      () => Column(
        children: [
          TextField(
            onChanged: (value) => state.controller.mastitisSearchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'search_mastitis_records'.tr,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _healthMastitisDateButton(state, 
                  label: 'from'.tr,
                  date: state.controller.mastitisFromDate.value,
                  onTap: () => _healthPickMastitisDate(state, isFrom: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _healthMastitisDateButton(state, 
                  label: 'to'.tr,
                  date: state.controller.mastitisToDate.value,
                  onTap: () => _healthPickMastitisDate(state, isFrom: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _healthMastitisDateButton(_HealthViewState state, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final value = date == null ? label : "$label: ${DateFormat('dd/MM/yyyy').format(date)}";
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDEBDE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _healthPickMastitisDate(_HealthViewState state, {required bool isFrom}) async {
    final current = isFrom
        ? state.controller.mastitisFromDate.value
        : state.controller.mastitisToDate.value;
    final initialDate = current ?? DateTime.now();
    final picked = await showDatePicker(
      context: state.context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    if (isFrom) {
      state.controller.setMastitisDateRange(from: picked);
    } else {
      state.controller.setMastitisDateRange(to: picked);
    }
  }

Widget _healthMastitisResultFilters(_HealthViewState state) {
    final filters = <String, String>{
      'positive': 'positive'.tr,
      'negative': 'negative'.tr,
      'all': 'all'.tr,
    };

    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final selected = state.controller.mastitisResultFilter.value == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => state.controller.mastitisResultFilter.value = entry.key,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? AppColors.primary : const Color(0xFFDDEBDE),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

Future<void> _openHealthMastitisSheet(_HealthViewState state, BuildContext context) async {
    final selectedAnimalId = RxnInt();
    final testResult = 'positive'.obs;
    final localSaving = false.obs;

    await Get.bottomSheet(
      Obx(
        () {
          final animals = <HealthAnimalItem>[];
          final seenIds = <int>{};
          for (final animal in state.controller.availableMastitisAnimals) {
            if (animal.id <= 0 || !seenIds.add(animal.id)) {
              continue;
            }
            animals.add(animal);
          }

          final selectedId = selectedAnimalId.value;
          final matchingCount = selectedId == null
              ? 0
              : animals.where((animal) => animal.id == selectedId).length;
          final dropdownValue = matchingCount == 1 ? selectedId : null;
          if (selectedId != null && dropdownValue == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (selectedAnimalId.value == selectedId) {
                selectedAnimalId.value = null;
              }
            });
          }
          final reagentBalance = state.controller.reagentBalanceMl.value;
          final hasReagentForTest = reagentBalance >= 12;

          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  state._sheetHandle(),
                  Text(
                    'add_mastitis_record'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: dropdownValue,
                    isExpanded: true,
                    decoration: state._sheetDecoration('select_animal'.tr),
                    items: animals
                        .map(
                          (animal) => DropdownMenuItem<int>(
                            value: animal.id,
                            child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedAnimalId.value = value,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: testResult.value,
                    decoration: state._sheetDecoration('test_result'.tr),
                    items: [
                      DropdownMenuItem(value: 'positive', child: Text('positive'.tr)),
                      DropdownMenuItem(value: 'negative', child: Text('negative'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        testResult.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasReagentForTest
                          ? const Color(0xFFEFF7EF)
                          : const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasReagentForTest
                            ? const Color(0xFFDDEBDE)
                            : const Color(0xFFFFD6A8),
                      ),
                    ),
                    child: Text(
                      hasReagentForTest
                          ? '${'reagent_test_note'.tr} ${'available_reagent_balance'.tr}: ${reagentBalance.toStringAsFixed(2)} ml'
                          : 'no_reagent_available'.tr,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: hasReagentForTest
                            ? AppColors.grey.shade800
                            : const Color(0xFF9A5A00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (localSaving.value || state.controller.isSubmitting.value || !hasReagentForTest)
                          ? null
                          : () async {
                              final animalId = selectedAnimalId.value;
                              if (animalId == null || animalId <= 0) {
                                Get.snackbar('validation'.tr, 'select_animal'.tr);
                                return;
                              }

                              localSaving.value = true;
                              final ok = await state.controller.saveMastitis(
                                animalId: animalId,
                                testResult: testResult.value,
                              );
                              localSaving.value = false;
                              if (ok) {
                                state._closeSheetAndShowSuccess(
                                  state.controller.lastSubmitMessage.trim().isEmpty
                                      ? 'mastitis_record_saved_successfully'.tr
                                      : state.controller.lastSubmitMessage.trim(),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: (localSaving.value || state.controller.isSubmitting.value)
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Text('save_record'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

Future<void> _openHealthMastitisTreatmentSheet(_HealthViewState state, BuildContext context, MastitisGroupItem item) async {
  final treatmentController = TextEditingController();
  final selectedDate = DateTime.now().obs;
  final localSaving = false.obs;

  await Get.bottomSheet(
    Obx(
      () => Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              state._sheetHandle(),
              Text(
                'add_treatment'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '${item.animalName} - ${'tag'.tr} ${item.tagNumber}',
                style: TextStyle(
                  color: AppColors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: treatmentController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 3,
                decoration: state._sheetDecoration('treatment'.tr),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: state.context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    selectedDate.value = picked;
                  }
                },
                child: InputDecorator(
                  decoration: state._sheetDecoration('date'.tr),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate.value),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (localSaving.value || state.controller.isSubmitting.value)
                      ? null
                      : () async {
                          final treatment = treatmentController.text.trim();

                          if (treatment.isEmpty) {
                            Get.snackbar('validation'.tr, 'please_enter_treatment'.tr);
                            return;
                          }

                          localSaving.value = true;

                          final ok = await state.controller.addMastitisTreatment(
                            mastitisRecordId: item.caseId,
                            animalId: item.animalId,
                            treatment: treatment,
                            date: selectedDate.value,
                          );

                          localSaving.value = false;

                          if (ok) {
                            state._closeSheetAndShowSuccess(
                              state.controller.lastSubmitMessage.trim().isEmpty
                                  ? 'treatment_added_successfully'.tr
                                  : state.controller.lastSubmitMessage.trim(),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: (localSaving.value || state.controller.isSubmitting.value)
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          'save_treatment'.tr,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Future<void> _confirmHealthMastitisRecovered(_HealthViewState state, MastitisGroupItem item) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('confirm_recovery'.tr),
        content: Text('animal_recovered_confirm'.trParams({'name': item.animalName})),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('ok'.tr),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final saved = await state.controller.markMastitisRecovered(
      mastitisRecordId: item.caseId,
      animalId: item.animalId,
      date: DateTime.now(),
    );
    if (saved) {
      Get.snackbar(
        'success'.tr,
        state.controller.lastSubmitMessage.trim().isEmpty
            ? 'animal_marked_recovered'.tr
            : state.controller.lastSubmitMessage.trim(),
        duration: const Duration(seconds: 4),
      );
    }
  }
