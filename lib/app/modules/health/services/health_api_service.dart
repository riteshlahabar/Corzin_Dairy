part of '../controllers/health_controller.dart';

class HealthApiService {
  HealthApiService._();

  static final HealthApiService instance = HealthApiService._();

  Future<HealthApiResponse> get(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    return HealthApiResponse.fromResponse(response);
  }

  Future<HealthApiResponse> post(
    String endpoint,
    Map<String, String> payload,
  ) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    return HealthApiResponse.fromResponse(response);
  }
}

class HealthApiResponse {
  const HealthApiResponse({
    required this.statusCode,
    required this.data,
  });

  final int statusCode;
  final dynamic data;

  factory HealthApiResponse.fromResponse(http.Response response) {
    return HealthApiResponse(
      statusCode: response.statusCode,
      data: response.body.isNotEmpty ? jsonDecode(response.body) : {},
    );
  }

  bool get isSuccess {
    final codeOk = statusCode >= 200 && statusCode < 300;
    if (!codeOk) return false;
    if (data is! Map) return true;
    final status = data['status'];
    final success = data['success'];
    final statusOk =
        status == true ||
        status == 1 ||
        status?.toString().toLowerCase() == 'true';
    final successOk =
        success == true ||
        success == 1 ||
        success?.toString().toLowerCase() == 'true';
    return statusOk || successOk || data.isEmpty;
  }

  bool get hasTrueStatus => statusCode == 200 && data is Map && data['status'] == true;

  String message({required String fallback}) {
    if (data is! Map) return fallback;
    final message = data['message'];
    if (message == null) return fallback;
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final first = message.values.firstWhere(
        (value) => value != null && value.toString().trim().isNotEmpty,
        orElse: () => '',
      );
      final text = first.toString().trim();
      return text.isEmpty ? fallback : text;
    }
    final text = message.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
