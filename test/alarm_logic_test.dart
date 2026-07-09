import 'package:flutter_test/flutter_test.dart';
import 'package:monogatari_clock/models/alarm.dart';
import 'package:monogatari_clock/models/app_timer.dart';
import 'package:monogatari_clock/util/format.dart';

void main() {
  group('Alarm.nextTrigger', () {
    // 2026-07-08 是星期三。
    final DateTime wed = DateTime(2026, 7, 8, 10, 30);

    test('一次性：今天時刻未到則今天響', () {
      const Alarm a = Alarm(id: 1, hour: 22, minute: 0);
      expect(a.nextTrigger(wed), DateTime(2026, 7, 8, 22, 0));
    });

    test('一次性：今天時刻已過則明天響', () {
      const Alarm a = Alarm(id: 1, hour: 7, minute: 0);
      expect(a.nextTrigger(wed), DateTime(2026, 7, 9, 7, 0));
    });

    test('一次性：整分邊界不在當下觸發', () {
      const Alarm a = Alarm(id: 1, hour: 10, minute: 30);
      expect(a.nextTrigger(DateTime(2026, 7, 8, 10, 30)),
          DateTime(2026, 7, 9, 10, 30));
    });

    test('週期：挑最近的星期', () {
      // 週一與週五 07:00，從週三 10:30 看，最近是週五。
      const Alarm a =
          Alarm(id: 1, hour: 7, minute: 0, weekdays: <int>{1, 5});
      expect(a.nextTrigger(wed), DateTime(2026, 7, 10, 7, 0));
    });

    test('週期：今天的時刻還沒到就是今天', () {
      const Alarm a =
          Alarm(id: 1, hour: 23, minute: 15, weekdays: <int>{3});
      expect(a.nextTrigger(wed), DateTime(2026, 7, 8, 23, 15));
    });

    test('週期：今天的時刻過了就下週同日', () {
      const Alarm a =
          Alarm(id: 1, hour: 9, minute: 0, weekdays: <int>{3});
      expect(a.nextTrigger(wed), DateTime(2026, 7, 15, 9, 0));
    });

    test('跳過下一次：越過被跳過的觸發', () {
      final Alarm a = Alarm(
        id: 1,
        hour: 7,
        minute: 0,
        weekdays: const <int>{1, 5},
        skippedUntil: DateTime(2026, 7, 10, 7, 0),
      );
      // 週五被跳過，落到下週一。
      expect(a.nextTrigger(wed), DateTime(2026, 7, 13, 7, 0));
    });

    test('每天重複跨越午夜', () {
      const Alarm a = Alarm(
          id: 1,
          hour: 0,
          minute: 5,
          weekdays: <int>{1, 2, 3, 4, 5, 6, 7});
      expect(a.nextTrigger(DateTime(2026, 7, 8, 23, 50)),
          DateTime(2026, 7, 9, 0, 5));
    });
  });

  group('Alarm JSON 往返', () {
    test('欄位完整保留', () {
      final Alarm a = Alarm(
        id: 42,
        hour: 6,
        minute: 45,
        weekdays: const <int>{2, 4, 6},
        label: '晨跑',
        enabled: false,
        snoozeMinutes: 5,
        vibrate: false,
        skippedUntil: DateTime(2026, 7, 9, 6, 45),
      );
      final Alarm b = Alarm.decodeList(Alarm.encodeList(<Alarm>[a])).single;
      expect(b.id, a.id);
      expect(b.hour, a.hour);
      expect(b.minute, a.minute);
      expect(b.weekdays, a.weekdays);
      expect(b.label, a.label);
      expect(b.enabled, a.enabled);
      expect(b.snoozeMinutes, a.snoozeMinutes);
      expect(b.vibrate, a.vibrate);
      expect(b.skippedUntil, a.skippedUntil);
    });
  });

  group('AppTimer', () {
    test('running 由牆鐘時間推算剩餘', () {
      final DateTime now = DateTime(2026, 7, 8, 12, 0, 0);
      final AppTimer t = AppTimer(
        id: 1,
        total: const Duration(minutes: 10),
        phase: TimerPhase.running,
        endAt: now.add(const Duration(minutes: 4)),
      );
      expect(t.remaining(now), const Duration(minutes: 4));
      expect(t.remaining(now.add(const Duration(minutes: 9))),
          Duration.zero);
    });

    test('paused 凍結剩餘並可 JSON 往返', () {
      const AppTimer t = AppTimer(
        id: 2,
        total: Duration(minutes: 3),
        label: '泡茶',
        phase: TimerPhase.paused,
        remainingOnPause: Duration(seconds: 90),
      );
      final AppTimer r =
          AppTimer.decodeList(AppTimer.encodeList(<AppTimer>[t])).single;
      expect(r.remaining(DateTime(2026, 1, 1)), const Duration(seconds: 90));
      expect(r.label, '泡茶');
      expect(r.phase, TimerPhase.paused);
    });
  });

  group('格式化', () {
    test('倒數', () {
      expect(formatCountdown(const Duration(minutes: 5, seconds: 3)), '05:03');
      expect(
          formatCountdown(
              const Duration(hours: 1, minutes: 2, seconds: 9)),
          '1:02:09');
    });

    test('碼錶', () {
      expect(
          formatStopwatch(
              const Duration(minutes: 1, seconds: 5, milliseconds: 370)),
          '01:05.37');
      expect(
          formatStopwatch(const Duration(hours: 2, seconds: 1)),
          '2:00:01.00');
    });
  });
}
