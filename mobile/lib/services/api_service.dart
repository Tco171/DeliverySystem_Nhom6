import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _configuredBaseUrl = '';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://localhost:5274';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5274';
    }
    return 'http://localhost:5274';
  }

  static String? currentUserId;

  static Future<Map<String, dynamic>> register({
    required String fullName,
    String? shopName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': fullName.trim(),
            'shopName': shopName == null || shopName.trim().isEmpty
                ? null
                : shopName.trim(),
            'phone': phone.trim(),
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) return data;
    throw Exception(data['message'] ?? 'Đăng ký không thành công.');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) {
      currentUserId = data['id']?.toString();
      return data;
    }
    throw Exception(data['message'] ?? 'Đăng nhập không thành công.');
  }

  static Future<Map<String, dynamic>> createQuote({
    required Map<String, dynamic> order,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/shipping-quotes'),
          headers: _headers(),
          body: jsonEncode(order),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) return data;
    throw Exception(data['message'] ?? 'Không tính được phí vận chuyển.');
  }

  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> order,
    required String quoteId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/shipments'),
          headers: _headers(),
          body: jsonEncode({...order, 'quoteId': quoteId}),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) return data;
    throw Exception(data['message'] ?? 'Không tạo được đơn hàng.');
  }

  static Future<List<Map<String, dynamic>>> listOrders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/shipments'), headers: _headers())
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) {
      final list = data['data'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception(data['message'] ?? 'Không tải được đơn hàng.');
  }

  static Future<Map<String, dynamic>> getOrder(String shipmentId) async {
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/v1/shipments/${Uri.encodeComponent(shipmentId)}',
          ),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) return data;
    throw Exception(data['message'] ?? 'Không tải được chi tiết đơn hàng.');
  }

  // Đồng bộ với GET /api/v1/shipments/{shipmentId}/complaints
  static Future<List<Map<String, dynamic>>> listComplaints(
    String shipmentId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/v1/shipments/${Uri.encodeComponent(shipmentId)}/complaints',
          ),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) {
      final list = data['data'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception(data['message'] ?? 'Không tải được báo cáo sự cố.');
  }

  // Đồng bộ với POST /api/v1/shipments/{shipmentId}/complaints
  static Future<Map<String, dynamic>> createComplaint({
    required String shipmentId,
    required String type,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/api/v1/shipments/${Uri.encodeComponent(shipmentId)}/complaints',
          ),
          headers: _headers(),
          body: jsonEncode({'type': type, 'content': content.trim()}),
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeResponse(response);
    if (_ok(response)) return data;
    throw Exception(data['message'] ?? 'Không gửi được báo cáo sự cố.');
  }

  static Map<String, String> _headers() {
    return {'Content-Type': 'application/json', 'X-User-Id': ?currentUserId};
  }

  static bool _ok(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'message': response.body};
    }
  }

  static void logout() {
    currentUserId = null;
  }
}
