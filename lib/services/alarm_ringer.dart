import 'dart:convert';

import 'package:alarm/alarm.dart' as ring;
import 'package:alarm/utils/alarm_set.dart' as ring;
import 'package:flutter/material.dart' show Color;

import '../models/alarm.dart';
import 'notification_service.dart';

/// 鬧鐘響鈴核心 —— 由 `alarm` 套件驅動：
/// 原生 AlarmManager 精確喚醒 + mediaPlayback 前台服務直接播放音頻，
/// 不經系統通知的聲音管道，到點即以完整音量出聲（三星時鐘同路數），
/// 亦是 Android 17 後台音訊收緊下的正規豁免路徑。
///
/// 排程槽位（通知 id = alarmId × 100 + 槽）：
///   0        一次性主鈴
///   10+w     星期 w 的本週主鈴（w = 1..7）
///   20+w     星期 w 的下週主鈴 —— 兩週深度，開一次應用即續滿
///   80 / 81  回響一／回響二（稍後再響間隔、兩倍間隔）
///
/// 套件不含週期概念，續期點：應用啟動、響鈴事件、停止／稍後再響、
/// 重啟（原生 BootReceiver 重掛所有未觸發排程）。
class AlarmRinger {
  AlarmRinger(this.strings);

  final NotificationStrings strings;

  static const int _slotOnce = 0;
  static const int _slotWeekA = 10; // +weekday
  static const int _slotWeekB = 20; // +weekday
  static const int _slotEchoA = 80;
  static const int _slotEchoB = 81;
  static const List<int> _allSlots = <int>[
    0, 11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 80, 81,
  ];

  static const String _bellAsset = 'assets/sounds/monogatari_bell.wav';
  static const Color _accent = Color(0xFFD9532F);

  /// 響鈴時回調（鬧鐘 id），由應用層導向響鈴頁。
  /// 回調註冊前到達的響鈴（全屏意圖冷啟動）先入袋，註冊時補發。
  set onRing(void Function(int alarmId)? callback) {
    _onRing = callback;
    final int? pending = _pendingRing;
    if (callback != null && pending != null) {
      _pendingRing = null;
      callback(pending);
    }
  }

  void Function(int alarmId)? _onRing;
  int? _pendingRing;

  final Set<int> _handledRings = <int>{};

  Future<void> init() async {
    await ring.Alarm.init();
    ring.Alarm.ringing.listen((ring.AlarmSet set) {
      for (final ring.AlarmSettings s in set.alarms) {
        if (_handledRings.contains(s.id)) continue;
        _handledRings.add(s.id);
        final int? alarmId = _alarmIdOf(s);
        if (alarmId == null) continue;
        if (_onRing != null) {
          _onRing!(alarmId);
        } else {
          _pendingRing = alarmId;
        }
      }
    });
  }

  static int? _alarmIdOf(ring.AlarmSettings s) {
    final String? payload = s.payload;
    if (payload == null) return null;
    try {
      final Map<String, Object?> data =
          (jsonDecode(payload) as Map).cast<String, Object?>();
      if (data['kind'] != 'alarm') return null;
      return data['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  ring.AlarmSettings _settings(Alarm alarm, int slot, DateTime at) {
    return ring.AlarmSettings(
      id: alarm.id * 100 + slot,
      dateTime: at,
      assetAudioPath: _bellAsset,
      loopAudio: true,
      vibrate: alarm.vibrate,
      warningNotificationOnKill: false,
      androidFullScreenIntent: true,
      allowAlarmOverlap: false,
      allowSameSecondScheduling: true,
      // 尊重系統鬧鐘音量（與系統時鐘一致），不做起步淡入，
      // 到點即聽得見 —— 「輕喚」由鈴聲自身的柔和音色承擔。
      volumeSettings: const ring.VolumeSettings.fixed(),
      notificationSettings: ring.NotificationSettings(
        title: alarm.label.isEmpty ? strings.alarmDefaultTitle : alarm.label,
        body: strings.alarmBody,
        stopButton: strings.stopAction,
        icon: 'ic_notification',
        iconColor: _accent,
      ),
      payload: jsonEncode(<String, Object?>{'kind': 'alarm', 'id': alarm.id}),
    );
  }

  Future<void> _cancelAll(int alarmId) async {
    for (final int slot in _allSlots) {
      await ring.Alarm.stop(alarmId * 100 + slot);
    }
  }

  Future<void> _setEchoes(Alarm alarm, DateTime ringAt) async {
    final Duration gap = Duration(minutes: alarm.snoozeMinutes);
    await ring.Alarm.set(
        alarmSettings: _settings(alarm, _slotEchoA, ringAt.add(gap)));
    await ring.Alarm.set(
        alarmSettings: _settings(alarm, _slotEchoB, ringAt.add(gap * 2)));
  }

  /// 重排某個鬧鐘的全部觸發（主鈴兩週深度 + 回響）。
  Future<void> scheduleAlarm(Alarm alarm, {DateTime? now}) async {
    await _cancelAll(alarm.id);
    if (!alarm.enabled) return;

    final DateTime base = now ?? DateTime.now();

    if (alarm.isOnce) {
      final DateTime at = alarm.nextTrigger(base);
      await ring.Alarm.set(alarmSettings: _settings(alarm, _slotOnce, at));
      await _setEchoes(alarm, at);
      return;
    }

    for (final int weekday in alarm.weekdays) {
      final Alarm single = alarm.copyWith(weekdays: <int>{weekday});
      final DateTime first = single.nextTrigger(base);
      await ring.Alarm.set(
          alarmSettings: _settings(alarm, _slotWeekA + weekday, first));
      await ring.Alarm.set(
        alarmSettings: _settings(
          alarm,
          _slotWeekB + weekday,
          first.add(const Duration(days: 7)),
        ),
      );
    }
    await _setEchoes(alarm, alarm.nextTrigger(base));
  }

  /// 停止當下響鈴並整體重排（一次性鬧鐘由呼叫方負責停用）。
  Future<void> stopRinging(Alarm alarm) async {
    _handledRings.removeWhere((int id) => id ~/ 100 == alarm.id);
    await scheduleAlarm(alarm);
  }

  /// 徹底移除（刪除鬧鐘、停用時）。
  Future<void> cancelAlarm(int alarmId) async {
    _handledRings.removeWhere((int id) => id ~/ 100 == alarmId);
    await _cancelAll(alarmId);
  }

  /// 稍後再響：靜音當下，「現在＋間隔」再響，後備再響一次；
  /// 週期主鈴同時重掛，不受影響。
  Future<void> snooze(Alarm alarm) async {
    _handledRings.removeWhere((int id) => id ~/ 100 == alarm.id);
    await _cancelAll(alarm.id);
    final DateTime now = DateTime.now();

    if (!alarm.isOnce) {
      for (final int weekday in alarm.weekdays) {
        final Alarm single = alarm.copyWith(weekdays: <int>{weekday});
        final DateTime first = single.nextTrigger(now);
        await ring.Alarm.set(
            alarmSettings: _settings(alarm, _slotWeekA + weekday, first));
        await ring.Alarm.set(
          alarmSettings: _settings(
            alarm,
            _slotWeekB + weekday,
            first.add(const Duration(days: 7)),
          ),
        );
      }
    }
    await _setEchoes(alarm, now);
  }

  /// 應用喚醒時的續期：把所有啟用中的鬧鐘重排到完整深度。
  Future<void> rearmAll(Iterable<Alarm> alarms) async {
    for (final Alarm a in alarms) {
      if (a.enabled) await scheduleAlarm(a);
    }
  }
}
