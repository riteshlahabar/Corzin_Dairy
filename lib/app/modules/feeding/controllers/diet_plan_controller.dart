import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';
import '../models/feeding_models.dart';
import '../repositories/diet_plan_repository.dart';
import '../services/diet_plan_api_response_service.dart';
import '../services/diet_plan_filter_service.dart';
import '../services/diet_plan_payload_service.dart';
import '../services/feeding_selection_service.dart';

part 'diet_plan_data_logic.dart';
part 'diet_plan_selection_logic.dart';
part 'diet_plan_metrics_logic.dart';
part 'diet_plan_submit_logic.dart';
part 'diet_plan_form_logic.dart';

class DietPlanController extends GetxController {
  DietPlanController({
    DietPlanRepository? repository,
    DietPlanFilterService? filterService,
    DietPlanPayloadService? payloadService,
    DietPlanApiResponseService? responseService,
    FeedingSelectionService? selectionService,
  }) : _repository = repository ?? const DietPlanRepository(),
       _filterService = filterService ?? const DietPlanFilterService(),
       _payloadService = payloadService ?? const DietPlanPayloadService(),
       _responseService = responseService ?? const DietPlanApiResponseService(),
       _selectionService = selectionService ?? const FeedingSelectionService();

  final DietPlanRepository _repository;
  final DietPlanFilterService _filterService;
  final DietPlanPayloadService _payloadService;
  final DietPlanApiResponseService _responseService;
  final FeedingSelectionService _selectionService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isMetricsLoading = false.obs;
  final RxBool isEditModeReady = false.obs;
  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedingPanModel> pans = <FeedingPanModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedingPanModel> selectedPan = Rxn<FeedingPanModel>();
  final RxList<DietFeedBlock> feedBlocks = <DietFeedBlock>[].obs;
  final RxList<FeedDietPlanModel> plans = <FeedDietPlanModel>[].obs;
  final TextEditingController dietPlanNameController = TextEditingController();
  final TextEditingController referenceDateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode dietPlanNameFocus = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxDouble bodyWeight = 0.0.obs;
  final RxDouble milkProduction = 0.0.obs;
  final RxDouble actualDmi = 0.0.obs;
  final RxDouble targetDmi = 0.0.obs;
  final RxDouble plannedDryMatter = 0.0.obs;
  final RxDouble dmiGap = 0.0.obs;
  final RxDouble actualDmiGap = 0.0.obs;
  final RxBool isNonMilkingContext = false.obs;

  int farmerId = 0;
  int _nextFeedBlockId = 1;
  int editingPlanId = 0;
  DateTime? _lastListRefreshAt;
  bool _isAutoRefreshingList = false;
  bool _isPreparingEditForm = false;
  bool _isAddFormPrepared = false;
  int _metricsRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    referenceDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.now());
    loadData();
  }

  @override
  void onClose() {
    dietPlanNameController.dispose();
    referenceDateController.dispose();
    searchController.dispose();
    dietPlanNameFocus.dispose();
    _clearFeedBlocks();
    super.onClose();
  }
}
