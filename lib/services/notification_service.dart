import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_timer.dart';

/// 通知文案。由 UI 層在語言解析完成後注入，
/// 讓排程出去的通知永遠跟隨系統語言。
class NotificationStrings {
  String alarmDefaultTitle = '鬧鐘';
  String alarmBody = '到點了，輕點以停止';
  String snoozeAction = '稍後再響';
  String stopAction = '停止';
  String timerDoneTitle = '時間到';
  String timerDoneBody = '計時結束';
  String timerChannelName = '計時器';
  String timerChannelDescription = '計時完成提醒';
}

/// 計時器完成提醒與通知權限。
/// 鬧鐘響鈴不走這裡 —— 見 [AlarmRinger]（原生前台服務直接播放音頻）。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String actionStop = 'stop';
  static const String _timerChannelId = 'monogatari_timer_v3';
  static const String _timerSound = 'monogatari_chime';

  /// FLAG_INSISTENT：讓提示音循環直到被處理。
  static const int _flagInsistent = 4;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final NotificationStrings strings = NotificationStrings();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final String localTz =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // 找不到時區資料時退回 UTC 偏移推算，不阻塞啟動。
    }

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(settings: settings);
  }

  /// 權限一律走系統彈窗／系統頁面，不在介面裡放任何授權按鈕。
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    // 鬧鐘應用聲明 USE_EXACT_ALARM 後系統自動授予；
    // 個別 ROM 收回時，引導到系統的精確鬧鐘設定頁。
    final bool? exact = await android.canScheduleExactNotifications();
    if (exact == false) {
      await android.requestExactAlarmsPermission();
    }
  }

  // ─── 計時器 ─────────────────────────────────────────────

  static int _timerNotificationId(int timerId) => 900000 + timerId;

  NotificationDetails _timerNotification() => NotificationDetails(
        android: AndroidNotificationDetails(
          _timerChannelId,
          strings.timerChannelName,
          channelDescription: strings.timerChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(_timerSound),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 250, 550, 350]),
          additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
          timeoutAfter: const Duration(minutes: 1).inMilliseconds,
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            // cancelNotification 由原生完成，無需任何後台回調。
            AndroidNotificationAction(
              actionStop,
              strings.stopAction,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );

  Future<void> scheduleTimer(AppTimer timer) async {
    final DateTime? endAt = timer.endAt;
    if (endAt == null) return;
    await _plugin.zonedSchedule(
      id: _timerNotificationId(timer.id),
      title: strings.timerDoneTitle,
      body: timer.label.isEmpty ? strings.timerDoneBody : timer.label,
      scheduledDate: tz.TZDateTime.from(endAt, tz.local),
      notificationDetails: _timerNotification(),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: jsonEncode(<String, Object?>{'kind': 'timer', 'id': timer.id}),
    );
  }

  Future<void> cancelTimer(int timerId) async {
    await _plugin.cancel(id: _timerNotificationId(timerId));
  }

  @visibleForTesting
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}
