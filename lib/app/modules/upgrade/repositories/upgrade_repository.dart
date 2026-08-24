import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/utils/api.dart';
import '../models/plan_model.dart';
import '../models/razorpay_order_model.dart';

class UpgradeRepository {
  const UpgradeRepository({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<PlanModel>?> fetchPlans({required int farmerId}) async {
    final uri = farmerId > 0
        ? Uri.parse('${Api.subscriptionPlans}?farmer_id=$farmerId')
        : Uri.parse(Api.subscriptionPlans);
    final response = await _get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 200 || data['status'] != true) {
      return null;
    }

    final list = data['data'] is List ? data['data'] as List : <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => PlanModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<UpgradeApiResult<void>> activateFreePlan({
    required int farmerId,
    required int planId,
  }) async {
    final response = await _post(
      Uri.parse(Api.subscriptionFree),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'farmer_id': farmerId, 'plan_id': planId}),
    );
    final data = _decodeMap(response.body);
    final message = data['message']?.toString().trim() ?? '';
    final success =
        (response.statusCode == 200 || response.statusCode == 201) &&
        data['status'] == true;
    return UpgradeApiResult<void>(success: success, message: message);
  }

  Future<UpgradeApiResult<RazorpayOrderModel>> createSubscriptionOrder({
    required int farmerId,
    required int planId,
  }) async {
    final response = await _post(
      Uri.parse(Api.subscriptionOrder),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'farmer_id': farmerId, 'plan_id': planId}),
    );

    final data = _decodeMap(response.body);
    final message = data['message']?.toString().trim() ?? '';
    if (response.statusCode != 200 ||
        data['status'] != true ||
        data['data'] is! Map) {
      return UpgradeApiResult<RazorpayOrderModel>(
        success: false,
        message: message,
      );
    }

    return UpgradeApiResult<RazorpayOrderModel>(
      success: true,
      message: message,
      data: RazorpayOrderModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      ),
    );
  }

  Future<bool> saveSubscriptionPurchase({
    required int farmerId,
    required PlanModel plan,
    required Map<String, dynamic> paymentMeta,
  }) async {
    final payload = <String, dynamic>{
      'farmer_id': farmerId,
      'plan_id': plan.id,
      'plan_name': plan.name,
      'amount': double.parse(plan.amount.toStringAsFixed(2)),
      'payment_method': 'razorpay',
      'payment_status': 'paid',
      ...paymentMeta,
    };

    final response = await _post(
      Uri.parse(Api.subscriptionPurchase),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeMap(response.body);
    return (response.statusCode == 200 || response.statusCode == 201) &&
        data['status'] == true;
  }

  Future<Map<String, String>> fetchAdminContact() async {
    final response = await _get(
      Uri.parse(Api.farmerSettings),
      headers: const {'Accept': 'application/json'},
    );
    final data = _decodeMap(response.body);
    final settings = data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : <String, dynamic>{};
    final contact = settings['admin_contact'] is Map
        ? Map<String, dynamic>.from(settings['admin_contact'] as Map)
        : <String, dynamic>{};
    return {
      'name': contact['name']?.toString().trim() ?? '',
      'number': contact['number']?.toString().trim() ?? '',
    };
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    return _client?.get(uri, headers: headers) ??
        http.get(uri, headers: headers);
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client?.post(uri, headers: headers, body: body) ??
        http.post(uri, headers: headers, body: body);
  }
}

class UpgradeApiResult<T> {
  const UpgradeApiResult({required this.success, this.message = '', this.data});

  final bool success;
  final String message;
  final T? data;
}
