// services/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String channelId   = 'reminders_channel_v2';
  static const String channelName = 'Reminders';
  static const String channelDesc = 'Task reminder notifications';

  static bool _ready = false;

  @pragma('vm:entry-point')
  static void onTapBackground(NotificationResponse response) {
    // TODO: افتح شاشة معينة/حلّل payload لو حابب
  }

  /// تهيئة أساسية: no-permission popups هنا – بس init + قناة
  static Future<void> init() async {
    // نستخدم مكتبة timezone فقط (لا نستخدم flutter_timezone)
    tzdata.initializeTimeZones(); // هنستخدم tz.UTC تحت

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: initAndroid);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {},
      onDidReceiveBackgroundNotificationResponse: onTapBackground,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // إنشاء القناة (لو موجودة مش هتتكرر)
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
      ),
    );

    _ready = true;
  }

  /// اتأكد إن كل حاجة جاهزة + طالب الأذونات لو ناقصة
  static Future<void> _ensureReadyAndPerms() async {
    if (!_ready) await init();

    if (!Platform.isAndroid) return;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ (POST_NOTIFICATIONS)
    final enabled = await androidImpl?.areNotificationsEnabled();
    if (enabled == false) {
      await androidImpl?.requestNotificationsPermission();
    }

    // Android 12+ (EXACT ALARMS)
    // دي بتفتح إعداد التطبيق علشان تفعّل "Alarms & reminders" لو مش مفعّلة
    await androidImpl?.requestExactAlarmsPermission();
  }

  static NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  /// إشعار فوري (اختبار سريع)
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureReadyAndPerms();
    await _plugin.show(id, title, body, _details(), payload: payload);
  }

  /// جدولة دقيقة باستخدام tz.UTC (من غير أي بلجن للتايم زون):
  /// بنحوّل التاريخ المحلي لـ UTC ونستخدم tz.UTC
  static Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureReadyAndPerms();

    // أمان: متجدولش في الماضي
    final minWhen = DateTime.now().add(const Duration(seconds: 5));
    final safeWhen = when.isBefore(minWhen) ? minWhen : when;

    // عشان نتجنب أي لبس في التايم زون:
    // 1) نحول التاريخ المحلي لوقت UTC
    // 2) ننشئ TZDateTime في منطقة tz.UTC
    final utcInstant = safeWhen.toUtc();
    final tzTime = tz.TZDateTime.from(utcInstant, tz.UTC);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();
}
