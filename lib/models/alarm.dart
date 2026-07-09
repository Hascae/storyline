import 'dart:convert';

/// 鬧鐘。weekdays 使用 DateTime.monday(1)..DateTime.sunday(7)；
/// 空集合代表僅響一次。
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.weekdays = const <int>{},
    this.label = '',
    this.enabled = true,
    this.snoozeMinutes = 10,
    this.vibrate = true,
    this.skippedUntil,
  });

  final int id;
  final int hour;
  final int minute;
  final Set<int> weekdays;
  final String label;
  final bool enabled;
  final int snoozeMinutes;
  final bool vibrate;

  /// 「跳過下一次」：此時刻（含）之前的觸發全部略過。
  final DateTime? skippedUntil;

  bool get isOnce => weekdays.isEmpty;

  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    String? label,
    bool? enabled,
    int? snoozeMinutes,
    bool? vibrate,
    DateTime? skippedUntil,
    bool clearSkip = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      vibrate: vibrate ?? this.vibrate,
      skippedUntil: clearSkip ? null : (skippedUntil ?? this.skippedUntil),
    );
  }

  /// 下一次應當響鈴的時刻（不考慮 enabled，由呼叫方過濾）。
  DateTime nextTrigger(DateTime now) {
    DateTime candidate = _firstCandidate(now);
    final DateTime? skip = skippedUntil;
    if (skip != null) {
      while (!candidate.isAfter(skip)) {
        candidate = _firstCandidate(candidate.add(const Duration(minutes: 1)));
      }
    }
    return candidate;
  }

  DateTime _firstCandidate(DateTime now) {
    DateTime at = DateTime(now.year, now.month, now.day, hour, minute);
    if (isOnce) {
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      return at;
    }
    for (int i = 0; i < 8; i++) {
      final DateTime day = at.add(Duration(days: i));
      // 跨日加法可能碰上夏令時，重建以保證牆鐘時刻正確。
      final DateTime fixed =
          DateTime(day.year, day.month, day.day, hour, minute);
      if (weekdays.contains(fixed.weekday) && fixed.isAfter(now)) {
        return fixed;
      }
    }
    // 理論上不可達：一週之內必有命中。
    return at.add(const Duration(days: 7));
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays.toList()..sort(),
        'label': label,
        'enabled': enabled,
        'snoozeMinutes': snoozeMinutes,
        'vibrate': vibrate,
        'skippedUntil': skippedUntil?.millisecondsSinceEpoch,
      };

  static Alarm fromJson(Map<String, Object?> json) {
    final int? skipMs = json['skippedUntil'] as int?;
    return Alarm(
      id: json['id']! as int,
      hour: json['hour']! as int,
      minute: json['minute']! as int,
      weekdays: ((json['weekdays'] as List<Object?>?) ?? const <Object?>[])
          .map((Object? e) => e! as int)
          .toSet(),
      label: (json['label'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
      snoozeMinutes: (json['snoozeMinutes'] as int?) ?? 10,
      vibrate: (json['vibrate'] as bool?) ?? true,
      skippedUntil: skipMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(skipMs),
    );
  }

  static String encodeList(List<Alarm> alarms) =>
      jsonEncode(alarms.map((Alarm a) => a.toJson()).toList());

  static List<Alarm> decodeList(String raw) {
    final List<Object?> data = jsonDecode(raw) as List<Object?>;
    return data
        .map((Object? e) => Alarm.fromJson((e! as Map).cast<String, Object?>()))
        .toList();
  }
}
