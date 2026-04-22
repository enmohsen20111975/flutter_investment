import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_parsers.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'investment_updates',
    'تحديثات الاستثمار',
    description: 'تحديثات الحالة والتذكيرات لمستخدمي تطبيق الاستثمار.',
    importance: Importance.high,
  );

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(settings);

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(_channel);

    _ready = true;
  }

  Future<void> scheduleFirstLaunchNotification() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('first_launch_notification_sent') ?? false) return;

    await _notifications.zonedSchedule(
      1001,
      'التطبيق جاهز',
      'تم تفعيل مزامنة السوق وتسجيل الدخول والتحقق من التحديثات.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'investment_updates',
          'تحديثات الاستثمار',
          channelDescription: 'تحديثات الحالة والتذكيرات لمستخدمي تطبيق الاستثمار.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await prefs.setBool('first_launch_notification_sent', true);
  }

  Future<void> showStatusNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'investment_updates',
          'تحديثات الاستثمار',
          channelDescription: 'تحديثات الحالة والتذكيرات لمستخدمي تطبيق الاستثمار.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> maybeNotifyMarketStatus(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMessage = prefs.getString('last_market_message');
    if (lastMessage == message) return;

    await showStatusNotification(title: 'تحديث حالة السوق', body: message);
    await prefs.setString('last_market_message', message);
  }

  Future<void> maybeNotifyInvestmentSummary(Map<String, dynamic> summary) async {
    final totalValue = toDouble(summary['total_value']);
    final gainLoss = toDouble(summary['total_gain_loss']);
    final message = gainLoss >= 0
        ? 'قيمة المحفظة ${totalValue.toStringAsFixed(0)} جنيه مع ربح ${gainLoss.toStringAsFixed(0)} جنيه.'
        : 'قيمة المحفظة ${totalValue.toStringAsFixed(0)} جنيه مع خسارة ${gainLoss.abs().toStringAsFixed(0)} جنيه.';

    final prefs = await SharedPreferences.getInstance();
    final lastMessage = prefs.getString('last_investment_message');
    if (lastMessage == message) return;

    await showStatusNotification(
      title: 'تغيرت حالة الاستثمار',
      body: message,
    );
    await prefs.setString('last_investment_message', message);
  }
}
