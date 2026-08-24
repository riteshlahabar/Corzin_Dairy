part of 'health_view.dart';

Widget _buildHealthReagentList(_HealthViewState state) {
    final records = state.controller.filteredReagentUsages;
    final balance = state.controller.reagentBalanceMl.value;
    return RefreshIndicator(
      onRefresh: () async {
        await state.controller.fetchReagentRecords();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _healthReagentBalanceCard(balance),
          const SizedBox(height: 10),
          _healthReagentSearchBar(state),
          const SizedBox(height: 12),
          if (records.isEmpty)
            state._inlineEmptyState(
              balance <= 0
                  ? 'no_reagent_available'.tr
                  : 'no_reagent_usage_found'.tr,
            )
          else
            ...records.map(
              (item) => state._card(
                title: item.displayTitle,
                subtitle: 'mastitis'.tr,
                dateText: item.date,
                rows: [
                  state._reagentInfo('reagent_used_quantity'.tr, '${item.quantityMl.toStringAsFixed(2)} ml'),
                  state._reagentInfo('reagent_balance'.tr, '${item.balanceAfterMl.toStringAsFixed(2)} ml'),
                ],
              ),
            ),
        ],
      ),
    );
  }

Widget _healthReagentBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EFE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.science_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reagent_balance'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${balance.toStringAsFixed(2)} ml',
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _healthReagentSearchBar(_HealthViewState state) {
    return TextField(
      onChanged: (value) => state.controller.reagentSearchQuery.value = value,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'search_reagent_records'.tr,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
    );
  }

Future<void> _openHealthReagentSheet(_HealthViewState state, BuildContext context) async {
    final quantityController = TextEditingController();
    final localSaving = false.obs;

    await Get.bottomSheet(
      Obx(
        () {
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
                    'add_reagent'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: state._sheetDecoration('reagent_quantity'.tr),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (localSaving.value || state.controller.isSubmitting.value)
                          ? null
                          : () async {
                              final quantity = double.tryParse(
                                quantityController.text.trim(),
                              );
                              if (quantity == null || quantity <= 0) {
                                Get.snackbar(
                                  'validation'.tr,
                                  'invalid_reagent_quantity'.tr,
                                );
                                return;
                              }

                              localSaving.value = true;
                              final ok = await state.controller.addReagent(
                                quantityMl: quantity,
                              );
                              localSaving.value = false;
                              if (ok) {
                                state._closeSheetAndShowSuccess(
                                  state.controller.lastSubmitMessage.trim().isEmpty
                                      ? 'reagent_added_successfully'.tr
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
