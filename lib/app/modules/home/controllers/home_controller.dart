import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/firebase_messaging_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  final RxBool isLoadingAnimals = false.obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxBool isUpdatingLifecycle = false.obs;
  final RxList<dynamic> animals = <dynamic>[].obs;
  final RxList<HomeSaleAnimalModel> saleAnimals = <HomeSaleAnimalModel>[].obs;
  final RxList<HomeAdminBannerModel> farmerBanners =
      <HomeAdminBannerModel>[].obs;
  final RxInt heroBannerIndex = 0.obs;
  final RxList<AnimalTypeOption> animalTypes = <AnimalTypeOption>[].obs;
  final RxMap<String, String> stats = <String, String>{
    'today_milk': '0 L',
    'today_feeding': '0 Kg',
    'total_milk': '0 L',
    'total_feeding': '0 Kg',
  }.obs;
  final RxList<HomePaymentModel> payments = <HomePaymentModel>[].obs;
  final Rx<FarmerPlanModel> currentPlan = const FarmerPlanModel(
    name: 'free_plan',
    amount: 'Rs 0',
    expiryDate: '30 days',
    startDate: '-',
    renewDate: '-',
  ).obs;
  final RxInt planDaysLeft = 30.obs;
  final RxBool planBlinkOn = false.obs;
  final RxString farmerName = ''.obs;
  final RxString farmerMobile = ''.obs;
  final RxString farmerPhoto = ''.obs;
  final RxString adminContactName = ''.obs;
  final RxString adminContactNumber = ''.obs;
  final RxBool isPlanLocked = false.obs;
  final RxString planLockMessage = ''.obs;
  final RxList<FarmerNotificationItem> notificationHistory =
      <FarmerNotificationItem>[].obs;
  final FirebaseMessagingService _firebaseMessagingService =
      FirebaseMessagingService();

  int farmerId = 0;
  Timer? _planBlinkTimer;
  Timer? _planDaysTimer;
  Timer? _heroBannerTimer;
  DateTime? _planRenewAt;
  static const String _globalNotificationKey = 'farmer_notifications_global';

  List<HomeSaleAnimalModel> get publicSaleAnimals =>
      saleAnimals.where((animal) => animal.farmerId != farmerId).toList();

  List<HomeSaleAnimalModel> get mySellingAnimals =>
      saleAnimals.where((animal) => animal.farmerId == farmerId).toList();

  int get heroBannerCount => publicSaleAnimals.length + farmerBanners.length;
  int get unreadNotificationCount =>
      notificationHistory.where((item) => item.isRead != true).length;

  @override
  void onInit() {
    super.onInit();
    unawaited(LocalNotificationService.instance.cancelAll());
    initHome();
    initialiseNotifications();
  }

  Future<void> initHome() async {
    await loadBaseData();
    await Future.wait([
      fetchAnimalTypes(),
      fetchAnimals(),
      fetchSaleAnimals(),
      fetchFarmerSettings(),
      loadDashboard(),
    ]);
  }

  Future<void> loadBaseData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    if (farmerId <= 0) {
      farmerId = await SessionService.getFarmerId();
      if (farmerId > 0) {
        await prefs.setInt('farmer_id', farmerId);
      }
    }
    final savedName = await SessionService.getFarmerName();
    final profile = await SessionService.getFarmerProfile();
    farmerName.value = _formatFarmerName(
      firstName: profile['first_name'] ?? '',
      middleName: profile['middle_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      fallbackName: savedName,
    );
    farmerMobile.value = await SessionService.getMobile();
    farmerPhoto.value = (profile['farmer_photo'] ?? '').trim();

    if (farmerId <= 0 && farmerMobile.value.trim().isNotEmpty) {
      await _loadFarmerIdFromProfileApi(farmerMobile.value.trim(), prefs);
    }
    await _loadNotificationHistory();
  }

  Future<void> fetchAnimalTypes() async {
    try {
      final response = await http.get(
        Uri.parse(Api.animalTypes),
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animalTypes.assignAll(
          list.map((item) => AnimalTypeOption.fromJson(item)).toList(),
        );
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> fetchAnimals({bool silent = false}) async {
    if (farmerId == 0) return;

    try {
      if (!silent) {
        isLoadingAnimals.value = true;
      }
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        animals.value = data['data'] ?? [];
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      if (!silent) {
        isLoadingAnimals.value = false;
      }
    }
  }

  Future<void> fetchSaleAnimals() async {
    try {
      final response = await http.get(
        Uri.parse(Api.animalsForSale),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode == 200 &&
          data['status'] == true &&
          data['data'] is List) {
        saleAnimals.assignAll(
          (data['data'] as List)
              .whereType<Map>()
              .map(
                (item) => HomeSaleAnimalModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
        _syncHeroBannerTimer();
      } else {
        saleAnimals.clear();
        _syncHeroBannerTimer();
      }
    } catch (_) {
      saleAnimals.clear();
      _syncHeroBannerTimer();
    }
  }

  Future<void> fetchFarmerSettings() async {
    try {
      final response = await http.get(
        Uri.parse(Api.farmerSettings),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      final settings = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      final contact = settings['admin_contact'] is Map
          ? Map<String, dynamic>.from(settings['admin_contact'] as Map)
          : <String, dynamic>{};
      adminContactName.value = contact['name']?.toString().trim() ?? '';
      adminContactNumber.value = contact['number']?.toString().trim() ?? '';
      final banners = settings['banners'] ?? [];
      if (response.statusCode == 200 &&
          data['status'] == true &&
          banners is List) {
        farmerBanners.assignAll(
          banners
              .whereType<Map>()
              .map(
                (item) => HomeAdminBannerModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((banner) => banner.imageUrl.trim().isNotEmpty)
              .toList(),
        );
        _syncHeroBannerTimer();
      } else {
        farmerBanners.clear();
        _syncHeroBannerTimer();
      }
    } catch (_) {
      farmerBanners.clear();
      _syncHeroBannerTimer();
    }
  }

  Future<void> fetchFarmerBanners() => fetchFarmerSettings();

  Future<void> callAdminSupport() async {
    if (adminContactNumber.value.trim().isEmpty) {
      await fetchFarmerSettings();
    }
    final number = adminContactNumber.value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      Get.snackbar('Error', 'Admin contact number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      Get.snackbar('Error', 'Unable to open dialer.');
    }
  }

  Future<void> loadDashboard({bool silent = false}) async {
    try {
      if (!silent) {
        isLoadingDashboard.value = true;
      }
      await Future.wait([
        _loadDairyPaymentsAndMilk(),
        _loadFeedingSummary(),
        _loadCurrentPlan(),
      ]);
    } finally {
      if (!silent) {
        isLoadingDashboard.value = false;
      }
    }
  }

  Future<bool> updateAnimalLifecycle({
    required int animalId,
    required String action,
    int? animalTypeId,
    String? notes,
  }) async {
    try {
      isUpdatingLifecycle.value = true;
      final payload = {
        'action': action,
        if (animalTypeId != null) 'animal_type_id': animalTypeId.toString(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      final response = await http.post(
        Uri.parse('${Api.animalLifecycle}/$animalId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await fetchAnimals();
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Animal lifecycle updated',
        );
        return true;
      }
      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to update animal lifecycle',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isUpdatingLifecycle.value = false;
    }
  }

  Future<void> refreshDashboard({bool silent = false}) async {
    await Future.wait([
      fetchAnimals(silent: silent),
      fetchSaleAnimals(),
      fetchFarmerSettings(),
      loadDashboard(silent: silent),
    ]);
  }

  Future<void> _loadDairyPaymentsAndMilk() async {
    if (farmerId == 0) {
      payments.clear();
      stats.addAll({
        'today_milk': _formatQuantity(0, 'L'),
        'total_milk': _formatQuantity(0, 'L'),
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.dairyPayments}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true) {
        payments.clear();
        stats.addAll({
          'today_milk': _formatQuantity(0, 'L'),
          'total_milk': _formatQuantity(0, 'L'),
        });
        return;
      }

      final list = data['data'] is List ? data['data'] as List : <dynamic>[];
      double todayMilkTotal = 0;
      double totalMilkTotal = 0;
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final mappedPayments = list.map((item) {
        final row = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);

        final history = row['history'] is List ? row['history'] as List : <dynamic>[];
        final parsedHistory = history
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();

        final latest = parsedHistory.isNotEmpty
            ? parsedHistory.first
            : <String, dynamic>{};

        double todayPayment = 0;
        double totalPayment = 0;
        for (final entry in parsedHistory) {
          final paid = _asDouble(entry['paid_amount']);
          totalPayment += paid;
          if ((entry['date_key'] ?? '').toString() == todayKey) {
            todayPayment = paid;
          }
        }
        final pendingPayment = _asDouble(latest['balance_amount']);

        final todayMilk = _asDouble(row['today_milk']);
        final totalMilk = _asDouble(row['total_milk']);

        todayMilkTotal += todayMilk;
        totalMilkTotal += totalMilk;

        return HomePaymentModel(
          dairyName: row['dairy_name']?.toString().trim().isNotEmpty == true
              ? row['dairy_name'].toString()
              : 'Dairy',
          todayPayment: _formatCurrency(todayPayment),
          totalPayment: _formatCurrency(totalPayment),
          pendingPayment: _formatCurrency(pendingPayment),
          todayMilk: _formatQuantity(todayMilk, 'L'),
          totalMilk: _formatQuantity(totalMilk, 'L'),
        );
      }).toList();

      payments.assignAll(mappedPayments);
      stats.addAll({
        'today_milk': _formatQuantity(todayMilkTotal, 'L'),
        'total_milk': _formatQuantity(totalMilkTotal, 'L'),
      });
    } catch (_) {
      payments.clear();
      stats.addAll({
        'today_milk': _formatQuantity(0, 'L'),
        'total_milk': _formatQuantity(0, 'L'),
      });
    }
  }

  Future<void> _loadFeedingSummary() async {
    if (farmerId == 0) {
      stats.addAll({
        'today_feeding': _formatQuantity(0, 'Kg'),
        'total_feeding': _formatQuantity(0, 'Kg'),
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.feedingSummary}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true) {
        stats.addAll({
          'today_feeding': _formatQuantity(0, 'Kg'),
          'total_feeding': _formatQuantity(0, 'Kg'),
        });
        return;
      }

      final summary = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : Map<String, dynamic>.from(data['data'] as Map? ?? {});
      final unit = _extractUnit(summary);
      final todayFeeding = _extractSummaryNumber(summary, const [
        'today_feeding',
        'today_feed',
        'today_quantity',
        'today_total',
      ]);
      final totalFeeding = _extractSummaryNumber(summary, const [
        'total_feeding',
        'total_feed',
        'total_quantity',
        'total',
      ]);

      stats.addAll({
        'today_feeding': _formatQuantity(todayFeeding, unit),
        'total_feeding': _formatQuantity(totalFeeding, unit),
      });
    } catch (_) {
      stats.addAll({
        'today_feeding': _formatQuantity(0, 'Kg'),
        'total_feeding': _formatQuantity(0, 'Kg'),
      });
    }
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final response = await http.get(
        Uri.parse('${Api.subscriptionPlans}?farmer_id=$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 ||
          data['status'] != true ||
          data['data'] is! List) {
        return;
      }

      final list = (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (list.isEmpty) return;

      final currentSubscription = data['current_subscription'] is Map
          ? Map<String, dynamic>.from(data['current_subscription'] as Map)
          : <String, dynamic>{};
      final currentPlanId = int.tryParse(
            currentSubscription['farmer_plan_id']?.toString() ?? '',
          ) ??
          0;
      final plan = currentPlanId > 0
          ? list.firstWhere(
              (item) =>
                  int.tryParse(item['id']?.toString() ?? '') == currentPlanId,
              orElse: () => list.firstWhere(
                (item) => item['is_current'] == true,
                orElse: () => list.first,
              ),
            )
          : list.firstWhere(
              (item) => item['is_current'] == true,
              orElse: () => list.firstWhere(
                (item) => item['is_popular'] == true,
                orElse: () => list.first,
              ),
            );

      int durationDays =
          int.tryParse((currentSubscription['duration_days'] ?? plan['duration_days'])?.toString() ?? '') ?? 0;
      final planName = currentSubscription['plan_name']?.toString().trim().isNotEmpty == true
          ? currentSubscription['plan_name'].toString()
          : plan['name']?.toString().trim().isNotEmpty == true
          ? plan['name'].toString()
          : 'free_plan';
      final isFreePlan =
          planName.toLowerCase().contains('free') ||
          _asDouble(currentSubscription['price'] ?? plan['price']) <= 0;
      if (isFreePlan && durationDays <= 0) {
        durationDays = 30;
      }
      final amount = currentSubscription['price_label']?.toString().trim().isNotEmpty == true
          ? currentSubscription['price_label'].toString()
          : plan['price_label']?.toString().trim().isNotEmpty == true
          ? plan['price_label'].toString()
          : _formatCurrency(_asDouble(currentSubscription['price'] ?? plan['price']));
      final backendStartAt = await _loadFarmerPlanStartDateFromProfile();
      final now = DateTime.now();
      final startAt =
          _readDate(currentSubscription, const [
            'start_date',
          ]) ??
          _readDate(plan, const [
            'start_date',
            'package_start_date',
            'subscribed_at',
            'created_at',
          ]) ??
          backendStartAt ??
          now;
      final renewAt =
          _readDate(currentSubscription, const [
            'due_date',
          ]) ??
          _readDate(plan, const [
            'renew_date',
            'renewal_date',
            'expiry_date',
            'expires_at',
            'end_date',
          ]) ??
          startAt.add(Duration(days: durationDays > 0 ? durationDays : 30));
      _planRenewAt = renewAt;
      final daysLeft = _daysLeftFromNow(renewAt);
      final lockedFromApi = data['access_locked'] == true ||
          currentSubscription['is_active'] == false ||
          currentSubscription['status']?.toString().toLowerCase() == 'expired' ||
          daysLeft <= 0;

      currentPlan.value = FarmerPlanModel(
        name: planName,
        amount: amount,
        expiryDate: durationDays > 0 ? '$durationDays days' : '30 days',
        startDate: DateFormat('dd-MM-yyyy').format(startAt),
        renewDate: DateFormat('dd-MM-yyyy').format(renewAt),
      );
      _setPlanDaysLeft(daysLeft > 0 ? daysLeft : 0);
      isPlanLocked.value = lockedFromApi;
      planLockMessage.value = lockedFromApi
          ? 'Your plan has expired. Please contact admin to upgrade your plan.'
          : '';
    } catch (_) {
      final now = DateTime.now();
      final renewAt = now.add(const Duration(days: 30));
      _planRenewAt = renewAt;
      _setPlanDaysLeft(30);
      currentPlan.value = const FarmerPlanModel(
        name: 'free_plan',
        amount: 'Rs 0',
        expiryDate: '30 days',
        startDate: '-',
        renewDate: '-',
      );
      isPlanLocked.value = false;
      planLockMessage.value = '';
    }
    _startPlanDaysTicker();
  }

  Future<DateTime?> _loadFarmerPlanStartDateFromProfile() async {
    final mobile = farmerMobile.value.trim();
    if (mobile.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true) return null;

      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return _readDate(payload, const [
          'subscription_start_date',
          'plan_start_date',
          'start_date',
          'created_at',
        ]);
      }
      if (payload is Map) {
        final mapped = Map<String, dynamic>.from(payload);
        return _readDate(mapped, const [
          'subscription_start_date',
          'plan_start_date',
          'start_date',
          'created_at',
        ]);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool get shouldBlinkPlan => planDaysLeft.value <= 10;

  void _setPlanDaysLeft(int days) {
    planDaysLeft.value = days < 0 ? 0 : days;
    _syncPlanBlinkTimer();
  }

  int _daysLeftFromNow(DateTime renewAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewDay = DateTime(renewAt.year, renewAt.month, renewAt.day);
    return renewDay.difference(today).inDays;
  }

  DateTime? _readDate(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final raw = source[key]?.toString().trim();
      if (raw == null || raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toLocal();
      try {
        return DateFormat('dd-MM-yyyy').parse(raw);
      } catch (_) {}
      try {
        return DateFormat('yyyy-MM-dd').parse(raw);
      } catch (_) {}
    }
    return null;
  }

  void _startPlanDaysTicker() {
    _planDaysTimer?.cancel();
    _planDaysTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      final renewAt = _planRenewAt;
      if (renewAt == null) return;
      _setPlanDaysLeft(_daysLeftFromNow(renewAt));
    });
  }

  void _syncPlanBlinkTimer() {
    _planBlinkTimer?.cancel();
    if (!shouldBlinkPlan) {
      planBlinkOn.value = false;
      return;
    }

    _planBlinkTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      planBlinkOn.value = !planBlinkOn.value;
    });
  }

  void _syncHeroBannerTimer() {
    final total = heroBannerCount;
    if (total <= 0) {
      heroBannerIndex.value = 0;
      _heroBannerTimer?.cancel();
      _heroBannerTimer = null;
      return;
    }

    if (heroBannerIndex.value >= total) {
      heroBannerIndex.value = 0;
    }

    if (total == 1) {
      _heroBannerTimer?.cancel();
      _heroBannerTimer = null;
      return;
    }

    if (_heroBannerTimer != null) return;
    _heroBannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final currentTotal = heroBannerCount;
      if (currentTotal <= 1) {
        _syncHeroBannerTimer();
        return;
      }
      heroBannerIndex.value = (heroBannerIndex.value + 1) % currentTotal;
    });
  }

  Future<void> initialiseNotifications() async {
    try {
      final token = await _firebaseMessagingService.initialise();
      if (token != null && token.isNotEmpty) {
        await _updateFarmerFcmToken(token);
      }

      _firebaseMessagingService.tokenRefreshStream().listen((token) async {
        if (token.isNotEmpty) {
          await _updateFarmerFcmToken(token);
        }
      });

      _firebaseMessagingService.foregroundMessageStream().listen(
        _handleRemoteMessage,
      );
      _firebaseMessagingService.messageOpenedAppStream().listen(
        _handleRemoteMessage,
      );

      final initialMessage = await _firebaseMessagingService
          .getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }
    } catch (_) {}
  }

  Future<void> _updateFarmerFcmToken(String token) async {
    if (farmerId <= 0) {
      await loadBaseData();
    }
    if (farmerId <= 0) {
      return;
    }

    final deviceId = await SessionService.getOrCreateDeviceId();
    final sessionToken = await SessionService.getActiveSessionToken();
    final response = await http.post(
      Uri.parse('${Api.farmerFcmToken}/$farmerId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fcm_token': token,
        'device_id': deviceId,
        'session_token': sessionToken,
      }),
    );
    if (response.statusCode == 401) {
      final payload = _safeDecodeBody(response.body);
      if (payload['force_logout'] == true) {
        await _forceLogoutFromAnotherDevice();
        return;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[FCM][Farmer] token update failed status=${response.statusCode} body=${response.body}',
      );
      return;
    }
    debugPrint(
      '[FCM][Farmer] token updated successfully for farmerId=$farmerId',
    );
  }

  Future<void> _loadFarmerIdFromProfileApi(
    String mobile,
    SharedPreferences prefs,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return;

      final data = _decodeBody(response.body);
      if (data['status'] != true) return;
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : <String, dynamic>{};
      final idRaw = payload['id'];
      final id = idRaw is int
          ? idRaw
          : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      if (id <= 0) return;

      farmerId = id;
      await SessionService.saveFarmerId(id);
      await prefs.setInt('farmer_id', id);
      await _loadNotificationHistory();
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    if (_isForceLogoutMessage(message)) {
      _forceLogoutFromAnotherDevice();
      return;
    }

    final title = _resolveNotificationTitle(message);
    final body = _resolveNotificationBody(message);
    final finalTitle = title?.isNotEmpty == true
        ? title!
        : (body?.isNotEmpty == true ? 'Notification' : '');
    final finalBody = body?.isNotEmpty == true ? body! : '';
    if (finalTitle.trim().isEmpty && finalBody.trim().isEmpty) {
      refreshDashboard();
      return;
    }

    final notificationId = _notificationIdForMessage(message);
    LocalNotificationService.instance.showMessage(
      title: finalTitle,
      body: finalBody,
      id: notificationId,
    );

    final item = FarmerNotificationItem(
      title: finalTitle,
      body: finalBody,
      createdAt: DateTime.now(),
      isRead: false,
      type: message.data['type']?.toString() ?? '',
      notificationId: notificationId,
      appointmentId: int.tryParse(
        message.data['appointment_id']?.toString() ?? '',
      ),
    );
    notificationHistory.insert(0, item);
    if (notificationHistory.length > 100) {
      notificationHistory.removeRange(100, notificationHistory.length);
    }
    _persistNotificationHistory();

    Get.snackbar(
      finalTitle,
      finalBody,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );

    refreshDashboard();
  }

  int _notificationIdForMessage(RemoteMessage message) {
    final appointmentId = int.tryParse(
      message.data['appointment_id']?.toString() ?? '',
    );
    if (appointmentId != null && appointmentId > 0) {
      return 800000 + appointmentId;
    }
    return message.hashCode;
  }

  Future<void> clearAppointmentScreenNotifications() async {
    final appointmentNotifications = notificationHistory.where((item) {
      final type = item.type.toLowerCase();
      return item.appointmentId != null ||
          type.contains('appointment') ||
          item.title.toLowerCase().contains('appointment') ||
          item.body.toLowerCase().contains('appointment');
    }).toList();

    for (final item in appointmentNotifications) {
      if (item.notificationId != null) {
        await LocalNotificationService.instance.cancel(item.notificationId!);
      }
    }

    // Also clear any FCM/system-posted app notifications that do not expose
    // the local notification id to Flutter.
    await LocalNotificationService.instance.cancelAll();
  }

  bool _isForceLogoutMessage(RemoteMessage message) {
    final type = message.data['type']?.toString().toLowerCase().trim() ?? '';
    final event = message.data['event']?.toString().toLowerCase().trim() ?? '';
    return type == 'force_logout' || event == 'force_logout';
  }

  Future<void> _forceLogoutFromAnotherDevice() async {
    await SessionService.forceLogoutFromAnotherDevice();
    Get.snackbar(
      'Logged out',
      'Your account was logged in on another mobile.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    Get.offAllNamed(Routes.LOGIN);
  }

  String? _resolveNotificationTitle(RemoteMessage message) {
    final fromNotification = message.notification?.title?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }

    final fromData = message.data['title']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) {
      return fromData;
    }

    final altFromData = message.data['notification_title']?.toString().trim();
    if (altFromData != null && altFromData.isNotEmpty) {
      return altFromData;
    }

    final fromMessage = message.data['message']?.toString().trim();
    if (fromMessage != null && fromMessage.isNotEmpty) {
      return 'Notification';
    }

    return null;
  }

  String? _resolveNotificationBody(RemoteMessage message) {
    var body = message.notification?.body?.trim();
    if (body == null || body.isEmpty) {
      final fromData = message.data['body']?.toString().trim();
      if (fromData != null && fromData.isNotEmpty) {
        body = fromData;
      }
    }

    if (body == null || body.isEmpty) {
      final altFromData = message.data['notification_body']?.toString().trim();
      if (altFromData != null && altFromData.isNotEmpty) {
        body = altFromData;
      }
    }

    if (body == null || body.isEmpty) {
      final fromMessage = message.data['message']?.toString().trim();
      if (fromMessage != null && fromMessage.isNotEmpty) {
        body = fromMessage;
      }
    }

    final otp = message.data['visit_otp']?.toString().trim().isNotEmpty == true
        ? message.data['visit_otp']!.toString().trim()
        : (message.data['otp']?.toString().trim().isNotEmpty == true
              ? message.data['otp']!.toString().trim()
              : '');
    if (otp.isNotEmpty) {
      final otpLine = 'Visit OTP: $otp';
      if (body == null || body.isEmpty) {
        body = otpLine;
      } else if (!body.contains(otp)) {
        body = '$body\n$otpLine';
      }
    }

    return body;
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentKey = _notificationStorageKey();
      final combined = <FarmerNotificationItem>[];

      void parseRaw(String? raw) {
        if (raw == null || raw.trim().isEmpty) return;
        final decoded = jsonDecode(raw);
        if (decoded is! List) return;
        combined.addAll(
          decoded.whereType<Map>().map(
            (item) => FarmerNotificationItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }

      parseRaw(prefs.getString(currentKey));
      if (currentKey != _globalNotificationKey) {
        parseRaw(prefs.getString(_globalNotificationKey));
      }

      combined.removeWhere(
        (item) => _isPlaceholderNotification(item.title, item.body),
      );
      if (combined.isEmpty) {
        notificationHistory.clear();
        return;
      }

      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notificationHistory.assignAll(combined.take(100).toList());
      await _persistNotificationHistory();
    } catch (_) {
      notificationHistory.clear();
    }
  }

  Future<void> _persistNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (notificationHistory.length > 100) {
        notificationHistory.removeRange(100, notificationHistory.length);
      }
      final payload = notificationHistory.map((item) => item.toJson()).toList();
      final encoded = jsonEncode(payload);
      await prefs.setString(_globalNotificationKey, encoded);
      if (farmerId > 0) {
        await prefs.setString('farmer_notifications_$farmerId', encoded);
      }
    } catch (_) {}
  }

  Future<void> clearNotificationHistory() async {
    notificationHistory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_globalNotificationKey);
      if (farmerId > 0) await prefs.remove('farmer_notifications_$farmerId');
    } catch (_) {}
  }

  Future<void> markNotificationAsRead(FarmerNotificationItem item) async {
    final index = notificationHistory.indexWhere(
      (row) =>
          row.createdAt == item.createdAt &&
          row.title == item.title &&
          row.body == item.body,
    );
    if (index == -1) return;

    final current = notificationHistory[index];
    if (current.isRead == true) return;

    notificationHistory[index] = current.copyWith(isRead: true);
    notificationHistory.refresh();
    await _persistNotificationHistory();
  }

  String _notificationStorageKey() {
    if (farmerId > 0) {
      return 'farmer_notifications_$farmerId';
    }
    return _globalNotificationKey;
  }

  bool _isPlaceholderNotification(String title, String body) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedBody = body.trim().toLowerCase();
    return normalizedTitle == 'notification' &&
        normalizedBody.contains('you have') &&
        normalizedBody.contains('new update');
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _safeDecodeBody(String body) {
    try {
      return _decodeBody(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final raw = value?.toString() ?? '';
    final direct = double.tryParse(raw);
    if (direct != null) return direct;
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw);
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  double _extractSummaryNumber(
    Map<String, dynamic> summary,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (summary.containsKey(key)) {
        return _asDouble(summary[key]);
      }
    }
    return 0;
  }

  String _extractUnit(Map<String, dynamic> summary) {
    final unit = summary['unit']?.toString().trim();
    if (unit != null && unit.isNotEmpty) return unit;
    final unitLabel = summary['unit_label']?.toString().trim();
    if (unitLabel != null && unitLabel.isNotEmpty) return unitLabel;
    return 'Kg';
  }

  String _formatCurrency(double amount) {
    return 'Rs ${_numberFormat.format(amount)}';
  }

  String _formatQuantity(double value, String unit) {
    return '${_numberFormat.format(value)} $unit';
  }

  String _formatFarmerName({
    required String firstName,
    required String middleName,
    required String lastName,
    required String fallbackName,
  }) {
    final first = firstName.trim();
    final middle = middleName.trim();
    final last = lastName.trim();

    final parts = <String>[
      if (first.isNotEmpty) first,
      if (middle.isNotEmpty) middle[0].toUpperCase(),
      if (last.isNotEmpty) last,
    ];

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return fallbackName.trim();
  }

  @override
  void onClose() {
    _planBlinkTimer?.cancel();
    _planDaysTimer?.cancel();
    _heroBannerTimer?.cancel();
    super.onClose();
  }
}

class FarmerNotificationItem {
  final String title;
  final String body;
  final DateTime createdAt;
  final bool? isRead;
  final String type;
  final int? notificationId;
  final int? appointmentId;

  const FarmerNotificationItem({
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.notificationId,
    this.appointmentId,
  });

  FarmerNotificationItem copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    int? notificationId,
    int? appointmentId,
  }) {
    return FarmerNotificationItem(
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead ?? false,
      type: type ?? this.type,
      notificationId: notificationId ?? this.notificationId,
      appointmentId: appointmentId ?? this.appointmentId,
    );
  }

  factory FarmerNotificationItem.fromJson(Map<String, dynamic> json) {
    return FarmerNotificationItem(
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
      type: json['type']?.toString() ?? '',
      notificationId: int.tryParse(json['notification_id']?.toString() ?? ''),
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'notification_id': notificationId,
      'appointment_id': appointmentId,
    };
  }
}

class AnimalTypeOption {
  final int id;
  final String name;

  AnimalTypeOption({required this.id, required this.name});

  factory AnimalTypeOption.fromJson(Map<String, dynamic> json) {
    return AnimalTypeOption(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class HomePaymentModel {
  final String dairyName;
  final String todayPayment;
  final String totalPayment;
  final String pendingPayment;
  final String todayMilk;
  final String totalMilk;

  const HomePaymentModel({
    required this.dairyName,
    required this.todayPayment,
    required this.totalPayment,
    required this.pendingPayment,
    required this.todayMilk,
    required this.totalMilk,
  });
}

class HomeSaleAnimalModel {
  final int id;
  final int farmerId;
  final String animalName;
  final String uniqueId;
  final String tagNumber;
  final String animalTypeName;
  final String panName;
  final String gender;
  final String age;
  final String birthDate;
  final String weight;
  final String breedName;
  final String lactationNumber;
  final String aiDate;
  final String sellingPrice;
  final String dailyMilkProduction;
  final String image;
  final String listedAt;

  const HomeSaleAnimalModel({
    required this.id,
    required this.farmerId,
    required this.animalName,
    required this.uniqueId,
    required this.tagNumber,
    required this.animalTypeName,
    required this.panName,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.weight,
    required this.breedName,
    required this.lactationNumber,
    required this.aiDate,
    required this.sellingPrice,
    required this.dailyMilkProduction,
    required this.image,
    required this.listedAt,
  });

  factory HomeSaleAnimalModel.fromJson(Map<String, dynamic> json) {
    return HomeSaleAnimalModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      farmerId: int.tryParse(json['farmer_id']?.toString() ?? '') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      uniqueId: json['unique_id']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      panName: json['pan_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: json['age_display']?.toString() ?? json['age']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      breedName: json['breed_name']?.toString() ?? '',
      lactationNumber: json['lactation_number']?.toString() ?? '',
      aiDate: json['ai_date']?.toString() ?? '',
      sellingPrice: json['selling_price']?.toString() ?? '',
      dailyMilkProduction: json['daily_milk_production']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      listedAt: json['listed_for_sale_at']?.toString() ?? '',
    );
  }
}

class HomeAdminBannerModel {
  final int id;
  final String title;
  final String imageUrl;

  const HomeAdminBannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory HomeAdminBannerModel.fromJson(Map<String, dynamic> json) {
    return HomeAdminBannerModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['image'] ?? '').toString(),
    );
  }
}

class FarmerPlanModel {
  final String name;
  final String amount;
  final String expiryDate;
  final String startDate;
  final String renewDate;

  const FarmerPlanModel({
    required this.name,
    required this.amount,
    required this.expiryDate,
    required this.startDate,
    required this.renewDate,
  });
}
