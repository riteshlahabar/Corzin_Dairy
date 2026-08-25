part of 'health_view.dart';

Widget _buildHealthDmiList(_HealthViewState state) {
    final records = state.controller.filteredDmiRecords;
    return RefreshIndicator(
      onRefresh: () async {
        await state.controller.fetchDmiRecords(forceRefresh: true);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _healthDmiSearchAndDateFilters(state),
          const SizedBox(height: 10),
          _healthDmiAnimalTypeFilters(state),
          const SizedBox(height: 12),
          if (records.isEmpty)
            state._inlineEmptyState('no_dmi_records_found'.tr)
          else
            ...records.map((item) {
              return state._card(
                title: item.displayTitle,
                subtitle: item.displaySubtitle,
                dateText: item.date,
                status: state._cardStatusLabel(item.alertStatus),
                rows: [
                  if (item.isPanGroup) state._info('animals'.tr, '${item.animalCount}'),
                  state._info('required_dmi'.tr, '${item.requiredDmi} Kg'),
                  state._info('body_weight'.tr, '${item.bodyWeight} Kg'),
                  if (!item.isNonMilking) state._info('total_milk'.tr, '${item.totalMilk} L'),
                  state._info('actual_dmi'.tr, '${item.actualDmi} Kg'),
                  if (item.notes.isNotEmpty) state._info('notes'.tr, item.notes),
                ],
              );
            }),
        ],
      ),
    );
  }

Widget _healthDmiSearchAndDateFilters(_HealthViewState state) {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: TextField(
            onChanged: (value) => state.controller.dmiSearchQuery.value = value,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'search_by_animal_name_or_tag'.tr,
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
              child: _healthDmiDateButton(state, 
                label: 'from'.tr,
                date: state.controller.dmiFromDate.value,
                onTap: () => _healthPickDmiDate(state, isFrom: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _healthDmiDateButton(state, 
                label: 'to'.tr,
                date: state.controller.dmiToDate.value,
                onTap: () => _healthPickDmiDate(state, isFrom: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _healthDmiDateButton(_HealthViewState state, {
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

Future<void> _healthPickDmiDate(_HealthViewState state, {required bool isFrom}) async {
    final initialDate = isFrom
        ? state.controller.dmiFromDate.value
        : state.controller.dmiToDate.value;
    final picked = await showDatePicker(
      context: state.context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    if (isFrom) {
      await state.controller.setDmiDateRange(from: picked);
    } else {
      await state.controller.setDmiDateRange(to: picked);
    }
  }

Widget _healthDmiAnimalTypeFilters(_HealthViewState state) {
    final filters = <String, String>{'all': 'all'.tr};
    for (final type in state.controller.dmiAnimalTypes) {
      filters[type.toLowerCase()] = type;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = state.controller.dmiAnimalTypeFilter.value.toLowerCase() == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(state._translatedAnimalTypeFilterLabel(entry.value)),
              selected: selected,
              onSelected: (_) => state.controller.dmiAnimalTypeFilter.value = entry.key,
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
    );
  }
