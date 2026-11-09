import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'staff_location_service.dart';

enum GeofenceStage { pickup, delivery }

class GeofenceTarget {
  const GeofenceTarget({
    required this.stage,
    required this.latitude,
    required this.longitude,
  });

  final GeofenceStage stage;
  final double latitude;
  final double longitude;

  String get apiStage => stage == GeofenceStage.pickup ? 'pickup' : 'delivery';
  String get label => stage == GeofenceStage.pickup ? 'điểm lấy hàng' : 'điểm giao hàng';
}

/// Theo dõi foreground khi Staff mở đơn đang xử lý; không tự đổi trạng thái đơn.
class GeofenceService {
  GeofenceService({this.radiusMeters = 150, this.maxAccuracyMeters = 100});

  final double radiusMeters;
  final double maxAccuracyMeters;
  StreamSubscription<Position>? _subscription;
  bool _requestInFlight = false;
  bool _arrivalRecorded = false;

  Future<void> start({
    required int assignmentId,
    required GeofenceTarget target,
    required void Function(String message) onStatus,
  }) async {
    await stop();
    _arrivalRecorded = false;
    if (assignmentId <= 0) {
      onStatus('Không xác định được phân công; Geofence chưa được bật.');
      return;
    }
    try {
      await StaffLocationService.ensureForegroundLocationPermission();
      onStatus('Đang theo dõi vị trí để phát hiện khi vào ${target.label} (bán kính ${radiusMeters.round()} m).');
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
      ).listen(
        (position) => _handlePosition(assignmentId: assignmentId, target: target, position: position, onStatus: onStatus),
        onError: (Object error) => onStatus('Không nhận được vị trí GPS: $error'),
      );
    } catch (error) {
      onStatus('$error'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handlePosition({
    required int assignmentId,
    required GeofenceTarget target,
    required Position position,
    required void Function(String message) onStatus,
  }) async {
    if (_arrivalRecorded || _requestInFlight) return;
    if (position.accuracy <= 0 || position.accuracy > maxAccuracyMeters) {
      onStatus('Tín hiệu GPS chưa đủ chính xác; đang chờ vị trí tốt hơn.');
      return;
    }
    final distance = Geolocator.distanceBetween(position.latitude, position.longitude, target.latitude, target.longitude);
    if (distance > radiusMeters) {
      onStatus('Còn cách ${target.label} khoảng ${distance.round()} m.');
      return;
    }
    _requestInFlight = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/staff/assignments/$assignmentId/geofence-arrivals'),
        headers: ApiService.authHeaders(),
        body: jsonEncode({'stage': target.apiStage, 'latitude': position.latitude, 'longitude': position.longitude, 'accuracy': position.accuracy}),
      ).timeout(const Duration(seconds: 10));
      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded is Map ? decoded['message'] ?? 'HTTP ${response.statusCode}' : 'HTTP ${response.statusCode}');
      }
      _arrivalRecorded = true;
      onStatus(decoded is Map && decoded['alreadyRecorded'] == true
          ? 'Sự kiện Staff đến ${target.label} đã được ghi nhận trước đó.'
          : 'Đã ghi nhận Staff đến ${target.label}. Hãy xác nhận lấy/giao hàng khi hoàn tất.');
      await stop();
    } catch (error) {
      onStatus('Đã vào vùng Geofence nhưng chưa lưu được sự kiện: $error');
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static double distanceBetweenMeters({required double fromLatitude, required double fromLongitude, required double toLatitude, required double toLongitude}) =>
      Geolocator.distanceBetween(fromLatitude, fromLongitude, toLatitude, toLongitude);
}
