import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();

  List<PriceAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  bool _isCreating = false;

  List<PriceAlert> get alerts => _alerts;
  List<PriceAlert> get activeAlerts =>
      _alerts.where((a) => a.isActive).toList();
  List<PriceAlert> get triggeredAlerts =>
      _alerts.where((a) => a.isTriggered).toList();
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;
  int get activeCount => activeAlerts.length;

  /// Load all alerts
  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _alertService.getAlerts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new alert
  Future<bool> createAlert({
    required String symbol,
    required String stockName,
    required double targetPrice,
    required String condition,
    String? notes,
  }) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final alert = await _alertService.createAlert(
        symbol: symbol,
        stockName: stockName,
        targetPrice: targetPrice,
        condition: condition,
        notes: notes,
      );
      _alerts.insert(0, alert);
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _alertService.deleteAlert(alertId);
      _alerts.removeWhere((a) => a.id == alertId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all as read
  void markAllTriggeredAsRead() {
    for (final alert in _alerts) {
      if (alert.isTriggered) {
        // Update in UI
      }
    }
    notifyListeners();
  }

  /// Refresh alert list
  Future<void> refresh() async {
    await loadAlerts();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
