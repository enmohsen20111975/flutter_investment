import '../models/alert.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AlertService {
  final ApiService _api = ApiService();

  /// Get all alerts
  Future<List<PriceAlert>> getAlerts() async {
    try {
      final response = await _api.get(AppConstants.alertsEndpoint);
      final List<dynamic> data = (response.data['alerts'] ?? response.data) as List<dynamic>;
      return data.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل التنبيهات');
    }
  }

  /// Create new alert
  Future<PriceAlert> createAlert({
    required String symbol,
    required String stockName,
    required double targetPrice,
    required String condition,
    String? notes,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.alertsEndpoint,
        data: {
          'symbol': symbol,
          'stockName': stockName,
          'targetPrice': targetPrice,
          'condition': condition,
          if (notes != null) 'notes': notes,
        },
      );
      return PriceAlert.fromJson((response.data['alert'] ?? response.data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في إنشاء التنبيه');
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _api.delete('${AppConstants.alertsEndpoint}/$alertId');
    } catch (e) {
      throw Exception('فشل في حذف التنبيه');
    }
  }

  /// Update alert status
  Future<void> updateAlertStatus(String alertId, String status) async {
    try {
      await _api.put(
        '${AppConstants.alertsEndpoint}/$alertId',
        data: {'status': status},
      );
    } catch (e) {
      throw Exception('فشل في تحديث التنبيه');
    }
  }

  /// Get active alerts count
  Future<int> getActiveAlertsCount() async {
    try {
      final response = await _api.get(
        AppConstants.alertsEndpoint,
        queryParameters: {'status': 'active'},
      );
      final List<dynamic> data = (response.data['alerts'] ?? response.data) as List<dynamic>;
      return data.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get triggered alerts
  Future<List<PriceAlert>> getTriggeredAlerts() async {
    try {
      final response = await _api.get(
        AppConstants.alertsEndpoint,
        queryParameters: {'status': 'triggered'},
      );
      final List<dynamic> data = (response.data['alerts'] ?? response.data) as List<dynamic>;
      return data.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
