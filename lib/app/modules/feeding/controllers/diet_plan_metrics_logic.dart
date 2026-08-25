part of 'diet_plan_controller.dart';

extension DietPlanMetricsLogic on DietPlanController {
  double get plannedDryMatterTotal => plannedDryMatter.value;

  void _refreshDmiSummary() {
    double totalDryMatter = 0;
    for (final block in feedBlocks) {
      totalDryMatter += block.totalDryMatter;
    }
    plannedDryMatter.value = double.parse(totalDryMatter.toStringAsFixed(2));
    dmiGap.value = double.parse(
      (plannedDryMatter.value - targetDmi.value).toStringAsFixed(2),
    );
  }

  void _clearMetricContext() {
    bodyWeight.value = 0;
    milkProduction.value = 0;
    actualDmi.value = 0;
    targetDmi.value = 0;
    actualDmiGap.value = 0;
    isNonMilkingContext.value = false;
    dmiGap.value = 0;
  }

  Future<void> pickReferenceDate() async {
    final today = DateTime.now();
    DateTime initialDate = today;
    final current = _selectedReferenceDate();
    if (current != null && !current.isAfter(today)) {
      initialDate = current;
    }

    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select reference date',
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
    referenceDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await refreshDietMetrics();
  }

  DateTime? _selectedReferenceDate() {
    final text = referenceDateController.text.trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  String get selectedReferenceDateApi {
    final parsed = _selectedReferenceDate() ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Future<void> refreshDietMetrics() async {
    final requestId = ++_metricsRequestId;
    final resolvedAnimal = _resolvedAnimalForPlan();
    _clearMetricContext();
    if (farmerId == 0 || resolvedAnimal == null) {
      isMetricsLoading.value = false;
      return;
    }

    try {
      isMetricsLoading.value = true;
      final params = <String, String>{
        'farmer_id': farmerId.toString(),
        'animal_id': resolvedAnimal.id.toString(),
        'date': selectedReferenceDateApi,
      };
      final pan = selectedPan.value;
      if (pan != null && pan.id > 0) {
        params['pan_id'] = pan.id.toString();
      }

      void apply(Map<String, dynamic> data) {
        if (requestId != _metricsRequestId) return;
        if (data['status'] != true) return;
        final payload = data['data'] as Map? ?? {};
        bodyWeight.value =
            double.tryParse((payload['body_weight'] ?? '0').toString()) ?? 0;
        milkProduction.value =
            double.tryParse((payload['milk_production'] ?? '0').toString()) ??
            0;
        actualDmi.value =
            double.tryParse((payload['actual_dmi'] ?? '0').toString()) ?? 0;
        targetDmi.value =
            double.tryParse((payload['target_dmi'] ?? '0').toString()) ?? 0;
        actualDmiGap.value =
            double.tryParse((payload['dmi_gap'] ?? '0').toString()) ?? 0;
        isNonMilkingContext.value = _responseService.asBool(
          payload['is_non_milking'],
        );
        isMetricsLoading.value = false;
      }

      final result = await _repository.fetchMetrics(params, onCached: apply);
      if (requestId != _metricsRequestId) return;
      final data = result.data;
      if (result.statusCode == 200 && data['status'] == true) {
        apply(data);
      } else {
        _clearMetricContext();
      }
    } catch (_) {
      if (requestId == _metricsRequestId) {
        _clearMetricContext();
      }
    } finally {
      if (requestId == _metricsRequestId) {
        isMetricsLoading.value = false;
        _refreshDmiSummary();
      }
    }
  }
}
