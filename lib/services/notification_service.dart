import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';
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
  String alarmChannelName = '鬧鐘';
  String alarmChannelDescription = '鬧鐘響鈴';
  String timerChannelName = '計時器';
  String timerChannelDescription = '計時完成提醒';
}

/// 鬧鐘響鈴時通知動作在後台 isolate 觸發。
///
/// 可靠性設計：稍後再響並不依賴這裡 —— 回響（T+間隔、T+2×間隔）
/// 在鬧鐘排入系統的那一刻就已一併排好。此處只做收斂：
/// 「稍後再響」把回響對齊到「現在+間隔」，「停止」撤掉剩餘回響。
/// 即使本回調完全沒被執行，稍後再響依然到點必響。
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == NotificationService.actionSnooze) {
    NotificationService.snoozeFromPayload(response.payload);
  } else if (response.actionId == NotificationService.actionStop) {
    NotificationService.stopFromPayload(response.payload);
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String actionSnooze = 'snooze';
  static const String actionStop = 'stop';

  // 渠道一經創建，聲音便不可變；鈴聲改版必須連同渠道版本一起升。
  static const String _alarmChannelId = 'monogatari_alarm_v3';
  static const String _timerChannelId = 'monogatari_timer_v3';
  static const String _alarmSound = 'monogatari_bell';
  static const String _timerSound = 'monogatari_chime';

  /// FLAG_INSISTENT：讓鈴聲循環直到被處理。
  static const int _flagInsistent = 4;

  /// 響鈴無人理會時的自動靜音時限。
  static const Duration _alarmTimeout = Duration(minutes: 8);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final NotificationStrings strings = NotificationStrings();

  /// 通知（點擊或全屏意圖）要求打開響鈴頁時回調，參數為鬧鐘 id。
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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
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

  void _onResponse(NotificationResponse response) {
    final Map<String, Object?>? payload = _decodePayload(response.payload);
    if (payload == null) return;
    if (response.actionId == actionSnooze) {
      snoozeFromPayload(response.payload);
      return;
    }
    if (response.actionId == actionStop) {
      return;
    }
    if (payload['kind'] == 'alarm') {
      onOpenRing?.call(payload['id']! as int);
    }
  }

  /// 冷啟動時檢查：應用是否由鬧鐘通知喚起。
  Future<int?> launchedByAlarm() async {
    final NotificationAppLaunchDetails? details =
        await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final NotificationResponse? response = details.notificationResponse;
    if (response == null || response.actionId != null) return null;
    final Map<String, Object?>? payload = _decodePayload(response.payload);
    if (payload == null || payload['kind'] != 'alarm') return null;
    return payload['id'] as int?;
  }

  static Map<String, Object?>? _decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  // ─── 鬧鐘 ───────────────────────────────────────────────
  //
  // 通知 id 槽位（alarmId × 10 + 槽）：
  //   0      一次性主鈴
  //   1..7   週期主鈴（按星期，系統級每週重複）
  //   8      回響一：主鈴後「稍後再響間隔」分鐘
  //   9      回響二：主鈴後兩倍間隔
  // 回響與主鈴同時從主 isolate 排入系統 —— 稍後再響、無人理會
  // 自動再響，皆不依賴任何後台執行。

  static const int _slotOnce = 0;
  static const int _slotEchoA = 8;
  static const int _slotEchoB = 9;
  static const int _slotCount = 10;

  static int _slotId(int alarmId, int slot) => alarmId * 10 + slot;
  static int _weekdayId(int alarmId, int weekday) => alarmId * 10 + weekday;

  String _alarmPayload(Alarm alarm) => jsonEncode(<String, Object?>{
        'kind': 'alarm',
        'id': alarm.id,
        'snoozeMinutes': alarm.snoozeMinutes,
        'vibrate': alarm.vibrate,
        'title': alarm.label.isEmpty ? strings.alarmDefaultTitle : alarm.label,
        'body': strings.alarmBody,
        'snoozeAction': strings.snoozeAction,
        'stopAction': strings.stopAction,
        'channelName': strings.alarmChannelName,
        'channelDescription': strings.alarmChannelDescription,
      });

  static AndroidNotificationDetails _alarmDetails({
    required bool vibrate,
    required String snoozeAction,
    required String stopAction,
    required String channelName,
    required String channelDescription,
  }) {
    return AndroidNotificationDetails(
      _alarmChannelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(_alarmSound),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: vibrate,
      // 漸進式振動：短促起步、逐步加長，與漸強鈴聲同步「輕喚」。
      vibrationPattern: vibrate
          ? Int64List.fromList(
              <int>[0, 180, 820, 280, 720, 420, 580, 600, 400])
          : null,
      additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
      ongoing: true,
      autoCancel: false,
      timeoutAfter: _alarmTimeout.inMilliseconds,
      when: null,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionSnooze,
          snoozeAction,
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionStop,
          stopAction,
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
  }

  NotificationDetails _alarmNotification(Alarm alarm) => NotificationDetails(
        android: _alarmDetails(
          vibrate: alarm.vibrate,
          snoozeAction: strings.snoozeAction,
          stopAction: strings.stopAction,
          channelName: strings.alarmChannelName,
          channelDescription: strings.alarmChannelDescription,
        ),
      );

  /// 排一發鬧鐘通知（主鈴或回響共用）。
  Future<void> _scheduleRing({
    required int id,
    required Alarm alarm,
    required DateTime at,
    DateTimeComponents? repeat,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: alarm.label.isEmpty ? strings.alarmDefaultTitle : alarm.label,
      body: strings.alarmBody,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _alarmNotification(alarm),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: _alarmPayload(alarm),
      matchDateTimeComponents: repeat,
    );
  }

  /// 把兩發回響對齊到某個主鈴時刻之後。
  Future<void> _scheduleEchoes(Alarm alarm, DateTime ringAt) async {
    final Duration gap = Duration(minutes: alarm.snoozeMinutes);
    await _scheduleRing(
        id: _slotId(alarm.id, _slotEchoA), alarm: alarm, at: ringAt.add(gap));
    await _scheduleRing(
        id: _slotId(alarm.id, _slotEchoB),
        alarm: alarm,
        at: ringAt.add(gap * 2));
  }

  /// 重排某個鬧鐘的全部觸發（主鈴 + 回響）。
  Future<void> scheduleAlarm(Alarm alarm, {DateTime? now}) async {
    await cancelAlarm(alarm.id);
    if (!alarm.enabled) return;

    final DateTime base = now ?? DateTime.now();

    if (alarm.isOnce) {
      final DateTime at = alarm.nextTrigger(base);
      await _scheduleRing(
          id: _slotId(alarm.id, _slotOnce), alarm: alarm, at: at);
      await _scheduleEchoes(alarm, at);
      return;
    }

    for (final int weekday in alarm.weekdays) {
      final Alarm single = alarm.copyWith(weekdays: <int>{weekday});
      await _scheduleRing(
        id: _weekdayId(alarm.id, weekday),
        alarm: alarm,
        at: single.nextTrigger(base),
        repeat: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    // 回響跟著最近的一次主鈴走；之後每次應用喚醒／停止／
    // 稍後再響時都會重新對齊到新的下一響。
    await _scheduleEchoes(alarm, alarm.nextTrigger(base));
  }

  Future<void> cancelAlarm(int alarmId) async {
    for (int slot = 0; slot < _slotCount; slot++) {
      await _plugin.cancel(id: _slotId(alarmId, slot));
    }
  }

  /// 撤下正在響與待響的通知（響鈴頁上的「停止」由呼叫方接手重排）。
  Future<void> dismissRinging(int alarmId) => cancelAlarm(alarmId);

  /// 從響鈴頁發起的稍後再響：
  /// 靜音當下，於「現在＋間隔」再響，並保留一發後備回響。
  Future<void> snoozeAlarm(Alarm alarm) async {
    await cancelAlarm(alarm.id);
    final DateTime now = DateTime.now();
    final Duration gap = Duration(minutes: alarm.snoozeMinutes);
    if (!alarm.isOnce) {
      // 週期主鈴照常掛回（回響將以稍後再響的時刻為準，見下）。
      for (final int weekday in alarm.weekdays) {
        final Alarm single = alarm.copyWith(weekdays: <int>{weekday});
        await _scheduleRing(
          id: _weekdayId(alarm.id, weekday),
          alarm: alarm,
          at: single.nextTrigger(now),
          repeat: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
    await _scheduleRing(
        id: _slotId(alarm.id, _slotEchoA), alarm: alarm, at: now.add(gap));
    await _scheduleRing(
        id: _slotId(alarm.id, _slotEchoB),
        alarm: alarm,
        at: now.add(gap * 2));
  }

  /// 後台 isolate 的「稍後再響」收斂：把回響對齊到「現在＋間隔」。
  /// 若本方法從未執行，預埋回響仍在原時刻響起。
  static Future<void> snoozeFromPayload(String? raw) async {
    final Map<String, Object?>? payload = _decodePayload(raw);
    if (payload == null || payload['kind'] != 'alarm') return;

    tzdata.initializeTimeZones();
    try {
      final String localTz =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {}

    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    final int alarmId = payload['id']! as int;
    final int minutes = (payload['snoozeMinutes'] as int?) ?? 10;
    final NotificationDetails details = NotificationDetails(
      android: _alarmDetails(
        vibrate: (payload['vibrate'] as bool?) ?? true,
        snoozeAction: (payload['snoozeAction'] as String?) ?? 'Snooze',
        stopAction: (payload['stopAction'] as String?) ?? 'Stop',
        channelName: (payload['channelName'] as String?) ?? 'Alarm',
        channelDescription:
            (payload['channelDescription'] as String?) ?? 'Alarm',
      ),
    );
    final DateTime now = DateTime.now();
    for (final (int slot, int factor) in <(int, int)>[
      (_slotEchoA, 1),
      (_slotEchoB, 2),
    ]) {
      await plugin.cancel(id: alarmId * 10 + slot);
      await plugin.zonedSchedule(
        id: alarmId * 10 + slot,
        title: payload['title'] as String?,
        body: payload['body'] as String?,
        scheduledDate: tz.TZDateTime.from(
            now.add(Duration(minutes: minutes * factor)), tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: raw,
      );
    }
  }

  /// 後台 isolate 的「停止」：撤掉剩餘回響。
  /// 只動回響槽，不碰週期主鈴的系統級重複。
  static Future<void> stopFromPayload(String? raw) async {
    final Map<String, Object?>? payload = _decodePayload(raw);
    if (payload == null || payload['kind'] != 'alarm') return;
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    final int alarmId = payload['id']! as int;
    await plugin.cancel(id: alarmId * 10 + _slotEchoA);
    await plugin.cancel(id: alarmId * 10 + _slotEchoB);
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
