import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';
import '../models/feeding_models.dart';
import '../repositories/feeding_repository.dart';
import '../services/feeding_date_service.dart';
import '../services/feeding_quantity_service.dart';
import '../services/feeding_schedule_service.dart';
import '../services/feeding_selection_service.dart';

part 'feeding_data_logic.dart';
part 'feeding_form_logic.dart';
part 'feeding_selection_logic.dart';
part 'feeding_submit_logic.dart';
part 'feeding_schedule_logic.dart';
part 'feeding_quantity_logic.dart';

class FeedingController extends GetxController {
  FeedingController({
    FeedingRepository? repository,
    FeedingDateService? dateService,
    FeedingQuantityService? quantityService,
    FeedingScheduleService? scheduleService,
    FeedingSelectionService? selectionService,
  }) : _repository = repository ?? const FeedingRepository(),
       _dateService = dateService ?? const FeedingDateService(),
       _quantityService = quantityService ?? const FeedingQuantityService(),
       _scheduleService = scheduleService ?? const FeedingScheduleService(),
       _selectionService = selectionService ?? const FeedingSelectionService();

  final FeedingRepository _repository;
  final FeedingDateService _dateService;
  final FeedingQuantityService _quantityService;
  final FeedingScheduleService _scheduleService;
  final FeedingSelectionService _selectionService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController ratePerUnitController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final FocusNode quantityFocus = FocusNode();
  final FocusNode ratePerUnitFocus = FocusNode();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isScheduleLoading = false.obs;

  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedingPanModel> pans = <FeedingPanModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final RxList<FeedDietPlanModel> dietPlans = <FeedDietPlanModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedingPanModel> selectedPan = Rxn<FeedingPanModel>();
  final Rxn<FeedTypeModel> selectedFeedType = Rxn<FeedTypeModel>();
  final Rxn<FeedDietPlanModel> selectedDietPlan = Rxn<FeedDietPlanModel>();
  final RxnInt selectedDietPlanId = RxnInt();
  final RxString selectedUnit = 'Kg'.obs;
  final RxString selectedFeedingTime = 'Morning'.obs;
  final RxList<String> availableFeedingTimes = <String>['Morning'].obs;
  final Rx<DateTime> entryCalendarMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final RxMap<String, int> monthEntryCounts = <String, int>{}.obs;
  final RxDouble packageQuantity = 0.0.obs;
  final RxDouble totalSubtypeQuantity = 0.0.obs;
  final RxDouble balanceQuantity = 0.0.obs;
  final RxDouble feedingCost = 0.0.obs;
  final RxInt dietPlanDays = 0.obs;
  final RxInt dietPlanDaysRemaining = 0.obs;

  final RxMap<int, bool> subtypeSelected = <int, bool>{}.obs;
  final Map<int, TextEditingController> subtypeQuantityControllers = {};

  int farmerId = 0;
  int _dietPlanRequestSerial = 0;
  List<Map<String, dynamic>> _feedingRows = <Map<String, dynamic>>[];
  @override
  void onInit() {
    super.onInit();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    quantityController.addListener(_recalculateBalance);
    quantityController.addListener(_recalculateFeedingCost);
    ratePerUnitController.addListener(_recalculateFeedingCost);
    initData();
  }

  @override
  void onClose() {
    quantityController.removeListener(_recalculateBalance);
    quantityController.removeListener(_recalculateFeedingCost);
    ratePerUnitController.removeListener(_recalculateFeedingCost);
    dateController.dispose();
    quantityController.dispose();
    ratePerUnitController.dispose();
    notesController.dispose();
    quantityFocus.dispose();
    ratePerUnitFocus.dispose();
    _clearSubtypeInputs();
    super.onClose();
  }
}
