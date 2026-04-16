import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase_messaging_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class HomeController extends GetxController {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  final RxBool isLoadingAnimals = false.obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxBool isUpdatingLifecycle = false.obs;
  final RxList<dynamic> animals = <dynamic>[].obs;
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
  ).obs;
  final RxInt planDaysLeft = 30.obs;
  final RxBool planBlinkOn = false.obs;
  final RxString farmerName = ''.obs;
  final RxString farmerMobile = ''.obs;
  final RxList<FarmerNotificationItem> notificationHistory = <FarmerNotificationItem>[].obs;
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  int farmerId = 0;
  Timer? _planBlinkTimer;

  @override
  void onInit() {
    super.onInit();
    initHome();
    initialiseNotifications();
  }

  Future<void> initHome() async {
    await loadBaseData();
    await Future.wait([fetchAnimalTypes(), fetchAnimals(), loadDashboard()]);
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

    if (farmerId <= 0 && farmerMobile.value.trim().isNotEmpty) {
      await _loadFarmerIdFromProfileApi(farmerMobile.value.trim(), prefs);
    }
    await _loadNotificationHistory();
  }

  Future<void> fetchAnimalTypes() async {
    try {
      final response = await http.get(Uri.parse(Api.animalTypes), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animalTypes.assignAll(list.map((item) => AnimalTypeOption.fromJson(item)).toList());
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;

    try {
      isLoadingAnimals.value = true;
      final response = await http.get(Uri.parse('${Api.animalList}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        animals.value = data['data'] ?? [];
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isLoadingAnimals.value = false;
    }
  }

  Future<void> loadDashboard() async {
    try {
      isLoadingDashboard.value = true;
      await Future.wait([
        _loadDairyPaymentsAndMilk(),
        _loadFeedingSummary(),
        _loadCurrentPlan(),
      ]);
    } finally {
      isLoadingDashboard.value = false;
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
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await fetchAnimals();
        Get.snackbar('Success', data['message']?.toString() ?? 'Animal lifecycle updated');
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to update animal lifecycle');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isUpdatingLifecycle.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await Future.wait([fetchAnimals(), loadDashboard()]);
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

      final mappedPayments = list.map((item) {
        final row = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);

        final todayPayment = _asDouble(row['today_payment']);
        final totalPayment = _asDouble(row['total_payment']);
        final todayMilk = _asDouble(row['today_milk']);
        final totalMilk = _asDouble(row['total_milk']);
        final pendingFromApi = _asDouble(row['pending_payment']);
        final pendingPayment = pendingFromApi > 0
            ? pendingFromApi
            : (totalPayment - todayPayment).clamp(0, double.infinity).toDouble();

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
        Uri.parse(Api.subscriptionPlans),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true || data['data'] is! List) {
        return;
      }

      final list = (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (list.isEmpty) return;

      final plan = list.firstWhere(
        (item) => item['is_popular'] == true,
        orElse: () => list.first,
      );

      int durationDays = int.tryParse(plan['duration_days']?.toString() ?? '') ?? 0;
      final planName = plan['name']?.toString().trim().isNotEmpty == true
          ? plan['name'].toString()
          : 'free_plan';
      final isFreePlan = planName.toLowerCase().contains('free') ||
          _asDouble(plan['price']) <= 0;
      if (isFreePlan && durationDays <= 0) {
        durationDays = 30;
      }
      final amount = plan['price_label']?.toString().trim().isNotEmpty == true
          ? plan['price_label'].toString()
          : _formatCurrency(_asDouble(plan['price']));

      currentPlan.value = FarmerPlanModel(
        name: planName,
        amount: amount,
        expiryDate: durationDays > 0 ? '$durationDays days' : '30 days',
      );
      _setPlanDaysLeft(durationDays > 0 ? durationDays : 30);
    } catch (_) {
      _setPlanDaysLeft(30);
      currentPlan.value = const FarmerPlanModel(
        name: 'free_plan',
        amount: 'Rs 0',
        expiryDate: '30 days',
      );
    }
  }

  bool get shouldBlinkPlan => planDaysLeft.value <= 10;

  void _setPlanDaysLeft(int days) {
    planDaysLeft.value = days <= 0 ? 30 : days;
    _syncPlanBlinkTimer();
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

      _firebaseMessagingService.foregroundMessageStream().listen(_handleRemoteMessage);
      _firebaseMessagingService.messageOpenedAppStream().listen(_handleRemoteMessage);

      final initialMessage = await _firebaseMessagingService.getInitialMessage();
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

    final response = await http.post(
      Uri.parse('${Api.farmerFcmToken}/$farmerId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': token}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[FCM][Farmer] token update failed status=${response.statusCode} body=${response.body}');
      return;
    }
    debugPrint('[FCM][Farmer] token updated successfully for farmerId=$farmerId');
  }

  Future<void> _loadFarmerIdFromProfileApi(String mobile, SharedPreferences prefs) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return;

      final data = _decodeBody(response.body);
      if (data['status'] != true) return;
      final payload = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : <String, dynamic>{};
      final idRaw = payload['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      if (id <= 0) return;

      farmerId = id;
      await SessionService.saveFarmerId(id);
      await prefs.setInt('farmer_id', id);
      await _loadNotificationHistory();
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final title = _resolveNotificationTitle(message);
    final body = _resolveNotificationBody(message);
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final finalTitle = title?.isNotEmpty == true ? title! : 'Notification';
    final finalBody = body?.isNotEmpty == true ? body! : 'You have a new update.';
    LocalNotificationService.instance.showMessage(
      title: finalTitle,
      body: finalBody,
      id: message.hashCode,
    );

    final item = FarmerNotificationItem(
      title: finalTitle,
      body: finalBody,
      createdAt: DateTime.now(),
      type: message.data['type']?.toString() ?? '',
    );
    notificationHistory.insert(0, item);
    _persistNotificationHistory();

    Get.snackbar(
      finalTitle,
      finalBody,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );

    refreshDashboard();
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
    if (farmerId <= 0) {
      notificationHistory.clear();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('farmer_notifications_$farmerId');
      if (raw == null || raw.trim().isEmpty) {
        notificationHistory.clear();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        notificationHistory.clear();
        return;
      }

      notificationHistory.assignAll(
        decoded
            .whereType<Map>()
            .map((item) => FarmerNotificationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    } catch (_) {
      notificationHistory.clear();
    }
  }

  Future<void> _persistNotificationHistory() async {
    if (farmerId <= 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = notificationHistory.take(100).toList();
      final payload = trimmed.map((item) => item.toJson()).toList();
      await prefs.setString('farmer_notifications_$farmerId', jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> clearNotificationHistory() async {
    notificationHistory.clear();
    if (farmerId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('farmer_notifications_$farmerId');
    } catch (_) {}
  }
  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final raw = value?.toString() ?? '';
    final direct = double.tryParse(raw);
    if (direct != null) return direct;
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw);
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  double _extractSummaryNumber(Map<String, dynamic> summary, List<String> keys) {
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
    super.onClose();
  }
}

class FarmerNotificationItem {
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;

  const FarmerNotificationItem({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
  });

  factory FarmerNotificationItem.fromJson(Map<String, dynamic> json) {
    return FarmerNotificationItem(
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'type': type,
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

class FarmerPlanModel {
  final String name;
  final String amount;
  final String expiryDate;

  const FarmerPlanModel({
    required this.name,
    required this.amount,
    required this.expiryDate,
  });
}



