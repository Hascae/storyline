import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../models/app_timer.dart';
import '../models/world_city.dart';
import 'notification_service.dart';

/// 應用的單一事實來源：鬧鐘、世界時鐘、計時器、碼錶。
/// 所有變更即刻持久化；running 狀態以牆鐘時間錨定，殺進程也不丟。
class ClockStore extends ChangeNotifier {
  ClockStore(this._notifications);

  final NotificationService _notifications;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _kAlarms = 'alarms.v1';
  static const String _kOnceArmed = 'alarms.onceArmed.v1';
  static const String _kCities = 'worldClock.cities.v1';
  static const String _kTimers = 'timers.v1';
  static const String _kNextAlarmId = 'alarms.nextId.v1';
  static const String _kNextTimerId = 'timers.nextId.v1';
  static const String _kStopwatch = 'stopwatch.v1';

  List<Alarm> _alarms = <Alarm>[];
  Map<String, int> _onceArmed = <String, int>{};
  List<String> _cityKeys = <String>[];
  List<AppTimer> _timers = <AppTimer>[];
  int _nextAlarmId = 1;
  int _nextTimerId = 1;

  // 碼錶。running 時 elapsed = accumulated + (now - startedAt)。
  bool swRunning = false;
  DateTime? swStartedAt;
  Duration swAccumulated = Duration.zero;
  List<Duration> swLaps = <Duration>[];

  String? _foregroundRingKey;
  bool loaded = false;

  List<Alarm> get alarms => List<Alarm>.unmodifiable(_alarms);
  List<AppTimer> get timers => List<AppTimer>.unmodifiable(_timers);

  List<WorldCity> get cities => _cityKeys
      .map(cityByKey)
      .whereType<WorldCity>()
      .toList(growable: false);

  Future<void> load() async {
    final String? rawAlarms = await _prefs.getString(_kAlarms);
    if (rawAlarms != null && rawAlarms.isNotEmpty) {
      _alarms = Alarm.decodeList(rawAlarms);
    }
    final String? rawArmed = await _prefs.getString(_kOnceArmed);
    if (rawArmed != null && rawArmed.isNotEmpty) {
      _onceArmed = (jsonDecode(rawArmed) as Map).cast<String, int>();
    }
    _cityKeys = await _prefs.getStringList(_kCities) ??
        <String>[
          cityKey(worldCityCatalog[5]), // 東京
          cityKey(worldCityCatalog[33]), // 倫敦
          cityKey(worldCityCatalog[43]), // 紐約
        ];
    final String? rawTimers = await _prefs.getString(_kTimers);
    if (rawTimers != null && rawTimers.isNotEmpty) {
      _timers = AppTimer.decodeList(rawTimers);
    }
    _nextAlarmId = await _prefs.getInt(_kNextAlarmId) ?? 1;
    _nextTimerId = await _prefs.getInt(_kNextTimerId) ?? 1;

    final String? rawSw = await _prefs.getString(_kStopwatch);
    if (rawSw != null && rawSw.isNotEmpty) {
      final Map<String, Object?> sw =
          (jsonDecode(rawSw) as Map).cast<String, Object?>();
      swRunning = (sw['running'] as bool?) ?? false;
      final int? startMs = sw['startedAt'] as int?;
      swStartedAt =
          startMs == null ? null : DateTime.fromMillisecondsSinceEpoch(startMs);
      swAccumulated = Duration(milliseconds: (sw['accumulated'] as int?) ?? 0);
      swLaps = ((sw['laps'] as List<Object?>?) ?? const <Object?>[])
          .map((Object? e) => Duration(milliseconds: e! as int))
          .toList();
    }

    _reconcile(DateTime.now());
    loaded = true;
    notifyListeners();
  }

  /// 開機後、回到前台時的對賬：
  /// 已經響過的一次性鬧鐘歸於安睡，倒數到點的計時器落定。
  /// 寬限 90 秒，避免掐斷正在響鈴／剛按下稍後再響的那一輪。
  void _reconcile(DateTime now) {
    bool dirty = false;
    for (int i = 0; i < _alarms.length; i++) {
      final Alarm a = _alarms[i];
      if (!a.isOnce || !a.enabled) continue;
      final int? armed = _onceArmed['${a.id}'];
      if (armed != null &&
          DateTime.fromMillisecondsSinceEpoch(armed)
              .isBefore(now.subtract(const Duration(seconds: 90)))) {
        _alarms[i] = a.copyWith(enabled: false);
        _onceArmed.remove('${a.id}');
        // 殘留的回響一併從系統撤下。
        unawaited(_notifications.cancelAlarm(a.id));
        dirty = true;
      }
    }
    for (int i = 0; i < _timers.length; i++) {
      final AppTimer t = _timers[i];
      if (t.phase == TimerPhase.running &&
          t.remaining(now) == Duration.zero) {
        _timers[i] = t.copyWith(phase: TimerPhase.finished, clearEndAt: true);
        dirty = true;
      }
    }
    if (dirty) {
      _persistAlarms();
      _persistTimers();
    }
  }

  void tick(DateTime now) {
    _reconcile(now);
    notifyListeners();
  }

  // ─── 鬧鐘 ───────────────────────────────────────────────

  Alarm? alarmById(int id) {
    for (final Alarm a in _alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  int newAlarmId() => _nextAlarmId;

  Future<void> upsertAlarm(Alarm alarm) async {
    final int index = _alarms.indexWhere((Alarm a) => a.id == alarm.id);
    if (index >= 0) {
      _alarms[index] = alarm;
    } else {
      _alarms.add(alarm);
      if (alarm.id >= _nextAlarmId) {
        _nextAlarmId = alarm.id + 1;
        await _prefs.setInt(_kNextAlarmId, _nextAlarmId);
      }
    }
    _sortAlarms();
    await _armAndPersist(alarm);
    notifyListeners();
  }

  Future<void> _armAndPersist(Alarm alarm) async {
    await _notifications.scheduleAlarm(alarm);
    if (alarm.isOnce && alarm.enabled) {
      // 標到回響鏈的最後一發：主鈴 + 兩倍稍後再響間隔。
      // 在此之前對賬不會把它視為已完成，自動再響因此不會被掐斷。
      _onceArmed['${alarm.id}'] = alarm
          .nextTrigger(DateTime.now())
          .add(Duration(minutes: alarm.snoozeMinutes * 2))
          .millisecondsSinceEpoch;
    } else {
      _onceArmed.remove('${alarm.id}');
    }
    await _persistAlarms();
  }

  Future<void> deleteAlarm(int id) async {
    _alarms.removeWhere((Alarm a) => a.id == id);
    _onceArmed.remove('$id');
    await _notifications.cancelAlarm(id);
    await _persistAlarms();
    notifyListeners();
  }

  Future<void> toggleAlarm(int id, bool enabled) async {
    final Alarm? alarm = alarmById(id);
    if (alarm == null) return;
    final Alarm updated =
        alarm.copyWith(enabled: enabled, clearSkip: !enabled);
    _alarms[_alarms.indexOf(alarm)] = updated;
    await _armAndPersist(updated);
    notifyListeners();
  }

  /// 跳過（或恢復）下一次響鈴 —— 週期鬧鐘限定。
  Future<void> setSkipNext(int id, bool skip) async {
    final Alarm? alarm = alarmById(id);
    if (alarm == null || alarm.isOnce) return;
    final Alarm updated = skip
        ? alarm.copyWith(skippedUntil: alarm.nextTrigger(DateTime.now()))
        : alarm.copyWith(clearSkip: true);
    _alarms[_alarms.indexOf(alarm)] = updated;
    await _armAndPersist(updated);
    notifyListeners();
  }

  /// 響鈴頁按下「停止」。
  Future<void> stopRinging(Alarm alarm) async {
    await _notifications.dismissRinging(alarm.id);
    if (alarm.isOnce) {
      await toggleAlarm(alarm.id, false);
    } else {
      // 循環排程仍在系統裡，僅撤下這一響。
      await _notifications.scheduleAlarm(alarm);
    }
  }

  Future<void> snooze(Alarm alarm) async {
    await _notifications.snoozeAlarm(alarm);
    if (alarm.isOnce) {
      // 一次性鬧鐘的「下一響」順延到稍後再響時刻，
      // 對賬不得在此之前把它視為已完成。
      _onceArmed['${alarm.id}'] = DateTime.now()
          .add(Duration(minutes: alarm.snoozeMinutes * 2))
          .millisecondsSinceEpoch;
      await _persistAlarms();
    }
  }

  /// 距離下一次響鈴最近的（鬧鐘, 時刻）。
  (Alarm, DateTime)? nextRing(DateTime now) {
    (Alarm, DateTime)? best;
    for (final Alarm a in _alarms) {
      if (!a.enabled) continue;
      final DateTime t = a.nextTrigger(now);
      if (best == null || t.isBefore(best.$2)) best = (a, t);
    }
    return best;
  }

  /// 前台響鈴偵測：到點的那一分鐘回傳鬧鐘（每分鐘至多一次）。
  Alarm? consumeForegroundRing(DateTime now) {
    final String key = '${now.day}-${now.hour}:${now.minute}';
    if (_foregroundRingKey == key) return null;
    for (final Alarm a in _alarms) {
      if (!a.enabled) continue;
      final DateTime t =
          a.nextTrigger(now.subtract(const Duration(seconds: 10)));
      if (t.difference(now).inSeconds.abs() <= 5) {
        _foregroundRingKey = key;
        return a;
      }
    }
    return null;
  }

  /// 開機或更新後，把所有啟用中的鬧鐘重新掛回系統。
  Future<void> rearmAll() async {
    for (final Alarm a in _alarms) {
      if (a.enabled) await _notifications.scheduleAlarm(a);
    }
  }

  void _sortAlarms() {
    _alarms.sort((Alarm a, Alarm b) {
      final int t = (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);
      return t != 0 ? t : a.id - b.id;
    });
  }

  Future<void> _persistAlarms() async {
    await _prefs.setString(_kAlarms, Alarm.encodeList(_alarms));
    await _prefs.setString(_kOnceArmed, jsonEncode(_onceArmed));
  }

  // ─── 世界時鐘 ───────────────────────────────────────────

  Future<void> addCity(WorldCity city) async {
    final String key = cityKey(city);
    if (_cityKeys.contains(key)) return;
    _cityKeys.add(key);
    await _prefs.setStringList(_kCities, _cityKeys);
    notifyListeners();
  }

  Future<void> removeCity(WorldCity city) async {
    _cityKeys.remove(cityKey(city));
    await _prefs.setStringList(_kCities, _cityKeys);
    notifyListeners();
  }

  bool hasCity(WorldCity city) => _cityKeys.contains(cityKey(city));

  // ─── 計時器 ─────────────────────────────────────────────

  Future<void> addTimer(Duration total, String label) async {
    final AppTimer timer = AppTimer(
      id: _nextTimerId++,
      total: total,
      label: label,
      phase: TimerPhase.running,
      endAt: DateTime.now().add(total),
    );
    _timers.insert(0, timer);
    await _prefs.setInt(_kNextTimerId, _nextTimerId);
    await _notifications.scheduleTimer(timer);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> pauseTimer(int id) async {
    final int i = _timers.indexWhere((AppTimer t) => t.id == id);
    if (i < 0 || _timers[i].phase != TimerPhase.running) return;
    final AppTimer t = _timers[i];
    _timers[i] = t.copyWith(
      phase: TimerPhase.paused,
      remainingOnPause: t.remaining(DateTime.now()),
      clearEndAt: true,
    );
    await _notifications.cancelTimer(id);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> resumeTimer(int id) async {
    final int i = _timers.indexWhere((AppTimer t) => t.id == id);
    if (i < 0 || _timers[i].phase != TimerPhase.paused) return;
    final AppTimer t = _timers[i];
    final Duration left = t.remainingOnPause ?? t.total;
    _timers[i] = t.copyWith(
      phase: TimerPhase.running,
      endAt: DateTime.now().add(left),
      clearRemaining: true,
    );
    await _notifications.scheduleTimer(_timers[i]);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> extendTimer(int id, Duration extra) async {
    final int i = _timers.indexWhere((AppTimer t) => t.id == id);
    if (i < 0) return;
    final AppTimer t = _timers[i];
    if (t.phase == TimerPhase.running) {
      _timers[i] = t.copyWith(endAt: t.endAt!.add(extra));
      await _notifications.cancelTimer(id);
      await _notifications.scheduleTimer(_timers[i]);
    } else if (t.phase == TimerPhase.paused) {
      _timers[i] =
          t.copyWith(remainingOnPause: (t.remainingOnPause ?? t.total) + extra);
    } else {
      return;
    }
    await _persistTimers();
    notifyListeners();
  }

  Future<void> resetTimer(int id) async {
    final int i = _timers.indexWhere((AppTimer t) => t.id == id);
    if (i < 0) return;
    _timers[i] = _timers[i].copyWith(
      phase: TimerPhase.idle,
      clearEndAt: true,
      clearRemaining: true,
    );
    await _notifications.cancelTimer(id);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> restartTimer(int id) async {
    final int i = _timers.indexWhere((AppTimer t) => t.id == id);
    if (i < 0) return;
    final AppTimer t = _timers[i];
    _timers[i] = t.copyWith(
      phase: TimerPhase.running,
      endAt: DateTime.now().add(t.total),
      clearRemaining: true,
    );
    await _notifications.cancelTimer(id);
    await _notifications.scheduleTimer(_timers[i]);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> removeTimer(int id) async {
    _timers.removeWhere((AppTimer t) => t.id == id);
    await _notifications.cancelTimer(id);
    await _persistTimers();
    notifyListeners();
  }

  Future<void> _persistTimers() async {
    await _prefs.setString(_kTimers, AppTimer.encodeList(_timers));
  }

  // ─── 碼錶 ───────────────────────────────────────────────

  Duration swElapsed(DateTime now) {
    if (swRunning && swStartedAt != null) {
      return swAccumulated + now.difference(swStartedAt!);
    }
    return swAccumulated;
  }

  Future<void> swStart() async {
    swRunning = true;
    swStartedAt = DateTime.now();
    await _persistStopwatch();
    notifyListeners();
  }

  Future<void> swPause() async {
    swAccumulated = swElapsed(DateTime.now());
    swRunning = false;
    swStartedAt = null;
    await _persistStopwatch();
    notifyListeners();
  }

  Future<void> swLap() async {
    swLaps.add(swElapsed(DateTime.now()));
    await _persistStopwatch();
    notifyListeners();
  }

  Future<void> swReset() async {
    swRunning = false;
    swStartedAt = null;
    swAccumulated = Duration.zero;
    swLaps = <Duration>[];
    await _persistStopwatch();
    notifyListeners();
  }

  Future<void> _persistStopwatch() async {
    await _prefs.setString(
      _kStopwatch,
      jsonEncode(<String, Object?>{
        'running': swRunning,
        'startedAt': swStartedAt?.millisecondsSinceEpoch,
        'accumulated': swAccumulated.inMilliseconds,
        'laps': swLaps.map((Duration d) => d.inMilliseconds).toList(),
      }),
    );
  }
}
