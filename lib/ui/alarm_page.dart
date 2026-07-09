import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../util/format.dart';
import '../widgets/ink_glyphs.dart';
import '../widgets/ink_kit.dart';
import 'alarm_edit_sheet.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key, required this.store});

  final ClockStore store;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 「距下次響鈴」每半分鐘校一次就足夠。
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String repeatSummary(AppLocalizations l10n, Alarm alarm) {
    if (alarm.isOnce) return l10n.once;
    const Set<int> workdays = <int>{1, 2, 3, 4, 5};
    const Set<int> weekend = <int>{6, 7};
    if (alarm.weekdays.length == 7) return l10n.everyDay;
    if (alarm.weekdays.length == 5 &&
        alarm.weekdays.containsAll(workdays)) {
      return l10n.workdays;
    }
    if (alarm.weekdays.length == 2 && alarm.weekdays.containsAll(weekend)) {
      return l10n.weekends;
    }
    final List<String> chars = <String>[
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final List<int> days = alarm.weekdays.toList()..sort();
    return days
        .map((int d) => '${l10n.weekPrefix}${chars[d - 1]}')
        .join('、');
  }

  void _openEditor([Alarm? alarm]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmEditSheet(store: widget.store, alarm: alarm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (BuildContext context, _) {
        final List<Alarm> alarms = widget.store.alarms;
        final DateTime now = DateTime.now();
        final (Alarm, DateTime)? next = widget.store.nextRing(now);

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.tabAlarm,
                            style: TextStyle(
                              fontSize: 22,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openEditor(),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child:
                                InkGlyph(Glyph.plus, size: 24, color: p.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      next == null
                          ? l10n.allAlarmsResting
                          : l10n.nextRingIn(
                              describeSpan(l10n, next.$2.difference(now))),
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: next == null ? p.faded : p.accent,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (alarms.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
                  child: Text(
                    l10n.noAlarms,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.8,
                      letterSpacing: 1.5,
                      color: p.faded,
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: alarms.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Hairline(),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Alarm alarm = alarms[index];
                  return _AlarmRow(
                    alarm: alarm,
                    use24h: use24h,
                    summary: repeatSummary(l10n, alarm),
                    onTap: () => _openEditor(alarm),
                    onToggle: (bool v) =>
                        widget.store.toggleAlarm(alarm.id, v),
                    onDelete: () => widget.store.deleteAlarm(alarm.id),
                    onResumeSkip: () =>
                        widget.store.setSkipNext(alarm.id, false),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      },
    );
  }
}

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({
    required this.alarm,
    required this.use24h,
    required this.summary,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    required this.onResumeSkip,
  });

  final Alarm alarm;
  final bool use24h;
  final String summary;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onResumeSkip;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Color main = alarm.enabled ? p.ink : p.faded;
    final int displayHour =
        use24h ? alarm.hour : ((alarm.hour + 11) % 12 + 1);
    final String meridiem =
        alarm.hour < 12 ? l10n.morning : l10n.afternoon;
    final bool skipped =
        !alarm.isOnce && alarm.enabled && alarm.skippedUntil != null;

    return Dismissible(
      key: ValueKey<int>(alarm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: p.accent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Text(
          l10n.delete,
          style: TextStyle(color: p.paper, letterSpacing: 2, fontSize: 14),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        if (!use24h)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              meridiem,
                              style:
                                  TextStyle(fontSize: 13, color: p.faded),
                            ),
                          ),
                        Text(
                          '${two(displayHour)}:${two(alarm.minute)}',
                          style: TextStyle(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                            color: main,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      alarm.label.isEmpty
                          ? summary
                          : '${alarm.label} · $summary',
                      style: TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 1,
                        color: p.faded,
                      ),
                    ),
                    if (skipped)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onResumeSkip,
                          child: Text(
                            '${l10n.skipNextOn} · ${l10n.resumeNext}',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              color: p.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              InkSwitch(value: alarm.enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
