part of 'health_view.dart';

Widget _buildHealthVaccinationList(_HealthViewState state) {
    final groups = state.controller.filteredVaccinationGroups;
    return RefreshIndicator(
      onRefresh: () async {
        await state.controller.fetchVaccinationRecords();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _healthVaccinationSearchAndDateFilters(state),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            state._inlineEmptyState('no_vaccination_records_found'.tr)
          else
            ...groups.map((item) {
              return state._card(
                title: item.displayTitle,
                subtitle: item.displaySubtitle,
                dateLabel: 'vaccination_date'.tr,
                dateText: item.latestDate,
                rows: [
                  if (item.panName.trim().isNotEmpty)
                    state._info('pan_name'.tr, item.panName),
                  ...item.records.map(
                    (record) => state._info(
                      record.date,
                      [
                        record.vaccineName.trim(),
                        if (record.doses.trim().isNotEmpty)
                          '${'doses'.tr}: ${record.doses.trim()}',
                        if (record.notes.trim().isNotEmpty) record.notes.trim(),
                      ].where((value) => value.isNotEmpty).join(' • '),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

Widget _healthVaccinationSearchAndDateFilters(_HealthViewState state) {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: TextField(
            onChanged: (value) => state.controller.vaccinationSearchQuery.value = value,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'search_vaccination_records'.tr,
              hintStyle: TextStyle(fontSize: 12.2, color: AppColors.grey.shade600),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 38),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _healthVaccinationDateButton(state, 
                label: 'from'.tr,
                date: state.controller.vaccinationFromDate.value,
                onTap: () => _healthPickVaccinationFilterDate(state, isFrom: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _healthVaccinationDateButton(state, 
                label: 'to'.tr,
                date: state.controller.vaccinationToDate.value,
                onTap: () => _healthPickVaccinationFilterDate(state, isFrom: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _healthVaccinationDateButton(_HealthViewState state, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
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
                "$label: ${DateFormat('dd/MM/yyyy').format(date)}",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _healthPickVaccinationFilterDate(_HealthViewState state, {required bool isFrom}) async {
    final initialDate = isFrom
        ? state.controller.vaccinationFromDate.value
        : state.controller.vaccinationToDate.value;
    final picked = await showDatePicker(
      context: state.context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    if (isFrom) {
      await state.controller.setVaccinationDateRange(from: picked);
    } else {
      await state.controller.setVaccinationDateRange(to: picked);
    }
  }

Future<void> _openHealthVaccinationSheet(_HealthViewState state, BuildContext context) async {
    final selectedAnimalId = RxnInt();
    final selectedVaccineId = RxnInt();
    final dosesController = TextEditingController();
    final notesController = TextEditingController();
    final selectedDate = DateTime.now().obs;
    final localSaving = false.obs;

    await Get.bottomSheet(
      Obx(
        () {
          final animals = <HealthAnimalItem>[];
          final seenAnimalIds = <int>{};
          for (final animal in state.controller.animals) {
            if (animal.id <= 0 || !seenAnimalIds.add(animal.id)) {
              continue;
            }
            animals.add(animal);
          }

          final vaccines = <HealthVaccineItem>[];
          final seenVaccineIds = <int>{};
          for (final vaccine in state.controller.vaccines) {
            if (vaccine.id <= 0 || !seenVaccineIds.add(vaccine.id)) {
              continue;
            }
            vaccines.add(vaccine);
          }

          final animalDropdownValue = animals.any((animal) => animal.id == selectedAnimalId.value)
              ? selectedAnimalId.value
              : null;
          final vaccineDropdownValue = vaccines.any((vaccine) => vaccine.id == selectedVaccineId.value)
              ? selectedVaccineId.value
              : null;

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
                    'add_vaccination_record'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: animalDropdownValue,
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
                  DropdownButtonFormField<int>(
                    initialValue: vaccineDropdownValue,
                    isExpanded: true,
                    decoration: state._sheetDecoration('select_vaccine'.tr),
                    items: vaccines
                        .map(
                          (vaccine) => DropdownMenuItem<int>(
                            value: vaccine.id,
                            child: Text(vaccine.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedVaccineId.value = value,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dosesController,
                    decoration: state._sheetDecoration('doses'.tr),
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
                      decoration: state._sheetDecoration('vaccination_date'.tr),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate.value),
                        style: const TextStyle(fontSize: 13.5, color: AppColors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 3,
                    decoration: state._sheetDecoration('notes'.tr),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (localSaving.value || state.controller.isSubmitting.value)
                          ? null
                          : () async {
                              final animalId = selectedAnimalId.value;
                              final vaccineId = selectedVaccineId.value;
                              final doses = dosesController.text.trim();

                              if (animalId == null || animalId <= 0) {
                                Get.snackbar('validation'.tr, 'select_animal'.tr);
                                return;
                              }
                              if (vaccineId == null || vaccineId <= 0) {
                                Get.snackbar('validation'.tr, 'select_vaccine'.tr);
                                return;
                              }
                              if (doses.isEmpty) {
                                Get.snackbar('validation'.tr, 'please_enter_doses'.tr);
                                return;
                              }

                              localSaving.value = true;
                              final ok = await state.controller.saveVaccination(
                                animalId: animalId,
                                vaccineId: vaccineId,
                                doses: doses,
                                vaccinationDate: selectedDate.value,
                                notes: notesController.text.trim(),
                              );
                              localSaving.value = false;

                              if (ok) {
                                state._closeSheetAndShowSuccess(
                                  state.controller.lastSubmitMessage.trim().isEmpty
                                      ? 'vaccination_record_saved_successfully'.tr
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
