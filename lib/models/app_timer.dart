import 'dart:convert';

enum TimerPhase { idle, running, paused, finished }

/// 倒數計時。支援多個同時進行；running 狀態以 endAt 錨定，
/// 即使行程被殺，重啟後仍可由牆鐘時間復原。
class AppTimer {
  const AppTimer({
    required this.id,
    required this.total,
    this.label = '',
    this.phase = TimerPhase.idle,
    this.endAt,
    this.remainingOnPause,
  });

  final int id;
  final Duration total;
  final String label;
  final TimerPhase phase;

  /// running 時的結束時刻。
  final DateTime? endAt;

  /// paused 時剩下的時間。
  final Duration? remainingOnPause;

  Duration remaining(DateTime now) {
    switch (phase) {
      case TimerPhase.idle:
        return total;
      case TimerPhase.paused:
        return remainingOnPause ?? total;
      case TimerPhase.finished:
        return Duration.zero;
      case TimerPhase.running:
        final Duration left = endAt!.difference(now);
        return left.isNegative ? Duration.zero : left;
    }
  }

  AppTimer copyWith({
    Duration? total,
    String? label,
    TimerPhase? phase,
    DateTime? endAt,
    Duration? remainingOnPause,
    bool clearEndAt = false,
    bool clearRemaining = false,
  }) {
    return AppTimer(
      id: id,
      total: total ?? this.total,
      label: label ?? this.label,
      phase: phase ?? this.phase,
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      remainingOnPause:
          clearRemaining ? null : (remainingOnPause ?? this.remainingOnPause),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'total': total.inMilliseconds,
        'label': label,
        'phase': phase.index,
        'endAt': endAt?.millisecondsSinceEpoch,
        'remainingOnPause': remainingOnPause?.inMilliseconds,
      };

  static AppTimer fromJson(Map<String, Object?> json) {
    final int? endMs = json['endAt'] as int?;
    final int? remMs = json['remainingOnPause'] as int?;
    return AppTimer(
      id: json['id']! as int,
      total: Duration(milliseconds: json['total']! as int),
      label: (json['label'] as String?) ?? '',
      phase: TimerPhase.values[(json['phase'] as int?) ?? 0],
      endAt: endMs == null ? null : DateTime.fromMillisecondsSinceEpoch(endMs),
      remainingOnPause: remMs == null ? null : Duration(milliseconds: remMs),
    );
  }

  static String encodeList(List<AppTimer> timers) =>
      jsonEncode(timers.map((AppTimer t) => t.toJson()).toList());

  static List<AppTimer> decodeList(String raw) {
    final List<Object?> data = jsonDecode(raw) as List<Object?>;
    return data
        .map((Object? e) =>
            AppTimer.fromJson((e! as Map).cast<String, Object?>()))
        .toList();
  }
}
