import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_timer.dart';
import 'alarm_ringer.dart';
import 'notification_strings.dart';

export 'notification_strings.dart';

/// 計時器完成提醒、通知權限、後台常駐權限，
/// 以及響鈴時蓋在桌面上的「稍後再響／停止」控制通知。
/// 鬧鐘的聲音不走這裡 —— 見 [AlarmRinger]（原生前台服務直接播放音頻）。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _timerChannelId = 'monogatari_timer_v3';
  static const String _ringChannelId = 'monogatari_ring_v1';
  static const String _timerSound = 'monogatari_chime';

  /// FLAG_INSISTENT：讓提示音循環直到被處理。
  static const int _flagInsistent = 4;

  static const MethodChannel _system =
      MethodChannel('com.monogatari.clock/system');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final NotificationStrings strings = NotificationStrings();

  /// 輕點響鈴控制通知本體時回調（導向響鈴頁）。
  void Function(int alarmId)? onOpenRing;

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
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: ringActionsBackground,
    );
  }

  void _onResponse(NotificationResponse response) {
    final String? raw = response.payload;
    if (raw == null || raw.isEmpty || response.actionId != null) return;
    try {
      final Map<String, Object?> data =
          (jsonDecode(raw) as Map).cast<String, Object?>();
      if (data['kind'] == 'ring') {
        final int? alarmId = data['id'] as int?;
        if (alarmId != null) onOpenRing?.call(alarmId);
      }
    } catch (_) {}
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
    // 後台常駐：請求排除在電池優化之外（系統彈窗），
    // 防止長時間閑置後行程被回收。
    try {
      final bool? ignoring =
          await _system.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      if (ignoring == false) {
        await _system.invokeMethod<void>('requestIgnoreBatteryOptimizations');
      }
    } catch (_) {
      // 個別 ROM 移除了該系統對話框，靜默略過。
    }
  }

  // ─── 響鈴控制（桌面彈窗）────────────────────────────────

  static int _ringControlsId(int alarmId) => 800000 + alarmId;

  /// 響鈴開始時蓋出一條最高優先級的控制通知：
  /// 亮屏時以懸浮橫幅出現在任何畫面之上，帶「稍後再響／停止」兩鍵；
  /// 鎖屏／滅屏時由引擎的全屏意圖直接亮出響鈴頁。
  Future<void> showRingControls({
    required int alarmId,
    required List<int> stopIds,
    required String title,
    required int snoozeMinutes,
    required bool vibrate,
  }) async {
    final String payload = jsonEncode(<String, Object?>{
      'kind': 'ring',
      'id': alarmId,
      'stopIds': stopIds,
      'snoozeMinutes': snoozeMinutes,
      'title': title,
      'body': strings.alarmBody,
      'stopAction': strings.stopAction,
      'vibrate': vibrate,
    });
    await _plugin.show(
      id: _ringControlsId(alarmId),
      title: title,
      body: strings.alarmBody,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _ringChannelId,
          strings.ringChannelName,
          channelDescription: strings.ringChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          // 聲音與震動由響鈴引擎負責，這條只負責「蓋出來讓人按」。
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              AlarmRinger.actionSnooze,
              strings.snoozeAction,
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              AlarmRinger.actionStop,
              strings.stopAction,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelRingControls(int alarmId) async {
    await _plugin.cancel(id: _ringControlsId(alarmId));
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
              AlarmRinger.actionStop,
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
