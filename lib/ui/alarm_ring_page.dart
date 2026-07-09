import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../util/format.dart';
import '../widgets/ink_kit.dart';

/// 響鈴頁：鎖屏上由全屏意圖喚起，亮屏時由通知或前台偵測進入。
/// 大字時刻、詩句、兩個不會按錯的大目標。
class AlarmRingPage extends StatefulWidget {
  const AlarmRingPage({super.key, required this.alarm, required this.store});

  final Alarm alarm;
  final ClockStore store;

  @override
  State<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends State<AlarmRingPage>
    with SingleTickerProviderStateMixin {
  late DateTime _now;
  Timer? _ticker;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // 朱色圓環緩緩呼吸，比閃爍溫和，也提示「正在響」。
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breath.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await widget.store.stopRinging(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await widget.store.snooze(widget.alarm);
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ChapterPalette p = ChapterTheme.of(context).palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        content: Text(
          l10n.snoozedToast(widget.alarm.snoozeMinutes),
          style: TextStyle(color: p.paper, letterSpacing: 1),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  String _verse(AppLocalizations l10n, Chapter c) {
    switch (c) {
      case Chapter.dawn:
        return l10n.verseDawn;
      case Chapter.day:
        return l10n.verseDay;
      case Chapter.dusk:
        return l10n.verseDusk;
      case Chapter.night:
        return l10n.verseNight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final Chapter chapter = ChapterTheme.of(context).chapter;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final int displayHour =
        use24h ? _now.hour : ((_now.hour + 11) % 12 + 1);
    final String meridiem = _now.hour < 12 ? l10n.morning : l10n.afternoon;
    final String title = widget.alarm.label.isEmpty
        ? l10n.alarmDefaultName
        : widget.alarm.label;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: p.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _breath,
                  builder: (BuildContext context, Widget? child) {
                    return Container(
                      width: 250,
                      height: 250,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: p.accent.withValues(
                              alpha: 0.35 + 0.5 * _breath.value),
                          width: 1.4,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!use24h)
                        Text(
                          meridiem,
                          style: TextStyle(
                            fontSize: 14,
                            color: p.faded,
                            letterSpacing: 2,
                          ),
                        ),
                      Text(
                        '${two(displayHour)}:${two(_now.minute)}',
                        style: TextStyle(
                          fontSize: 64,
                          height: 1.1,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          color: p.ink,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 2,
                          color: p.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _verse(l10n, chapter),
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.5,
                    color: p.faded,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _snooze,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${l10n.snooze} · ${l10n.minutesN(widget.alarm.snoozeMinutes)}',
                        style: TextStyle(
                          color: p.paper,
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: InkPill(label: l10n.stopAlarm, onTap: _stop),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
