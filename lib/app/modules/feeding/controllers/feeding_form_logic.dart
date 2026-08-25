part of 'feeding_controller.dart';

extension FeedingFormLogic on FeedingController {
  Future<void> pickDate() async {
    final today = DateTime.now();
    final current = _selectedFeedingDate() ?? today;
    final initialDate = current.isAfter(today) ? today : current;
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select feeding date',
      builder: (context, child) {
        final theme = Theme.of(context);
        const softGreen = Color(0xFFF4FAF4);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF95BE95),
              onPrimary: AppColors.black,
              surface: softGreen,
              onSurface: AppColors.black,
            ),
            dialogTheme: theme.dialogTheme.copyWith(backgroundColor: softGreen),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: softGreen,
              headerBackgroundColor: const Color(0xFFDDEEDC),
              headerForegroundColor: AppColors.black,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;

    dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    updateAvailableFeedingTimes();
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedPan.value = null;
    selectedFeedType.value = null;
    selectedDietPlan.value = null;
    selectedDietPlanId.value = null;
    selectedUnit.value = 'Kg';
    packageQuantity.value = 0;
    dietPlanDays.value = 0;
    dietPlanDaysRemaining.value = 0;
    _clearSubtypeInputs();
    quantityController.clear();
    ratePerUnitController.clear();
    notesController.clear();
    feedingCost.value = 0;
    balanceQuantity.value = packageQuantity.value;
    updateAvailableFeedingTimes();
  }
}
