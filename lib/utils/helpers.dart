import 'package:intl/intl.dart';

class Helpers {
  /// Format number with commas
  static String formatNumber(num number, {int decimalPlaces = 2}) {
    if (number == number.truncateToDouble()) {
      return NumberFormat('#,###').format(number);
    }
    return NumberFormat('#,###.${'#' * decimalPlaces}').format(number);
  }

  /// Format currency in EGP
  static String formatCurrency(num amount) {
    return '${formatNumber(amount)} ج.م';
  }

  /// Format percentage
  static String formatPercentage(num value, {bool showSign = true}) {
    final formatted = value.abs().toStringAsFixed(2);
    if (!showSign || value == 0) return '$formatted%';
    return '${value > 0 ? '+' : ''}$formatted%';
  }

  /// Format price change
  static String formatPriceChange(num change, {bool showSign = true}) {
    final formatted = formatNumber(change);
    if (!showSign || change == 0) return formatted;
    return '${change > 0 ? '+' : ''}$formatted';
  }

  /// Get change color
  static String getChangeColor(num change) {
    if (change > 0) return 'up';
    if (change < 0) return 'down';
    return 'neutral';
  }

  /// Format date
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar_EG').format(date);
  }

  /// Format time
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'ar_EG').format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  /// Format relative time
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return formatDate(date);
    }
  }

  /// Format large numbers (e.g., 1.5M, 2.3B)
  static String formatLargeNumber(num number) {
    if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(1)} مليار';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(1)} مليون';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(1)} ألف';
    }
    return formatNumber(number);
  }

  /// Format volume (trades count)
  static String formatVolume(int volume) {
    return formatLargeNumber(volume);
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Calculate profit/loss percentage
  static double calculateProfitPercentage(double buyPrice, double currentPrice) {
    if (buyPrice == 0) return 0;
    return ((currentPrice - buyPrice) / buyPrice) * 100;
  }

  /// Validate market hours
  static bool isMarketOpen() {
    final now = DateTime.now();
    // Sunday - Thursday, 10:00 - 14:30 Cairo Time
    if (now.weekday == DateTime.friday || now.weekday == DateTime.saturday) {
      return false;
    }
    final hour = now.hour;
    final minute = now.minute;
    final timeMinutes = hour * 60 + minute;
    return timeMinutes >= 600 && timeMinutes <= 870; // 10:00 - 14:30
  }

  /// Get market status text
  static String getMarketStatus() {
    if (isMarketOpen()) return 'السوق مفتوح';
    return 'السوق مغلق';
  }
}
