import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../widgets/ink_kit.dart';

/// 新建／編輯鬧鐘的底部表單：滾輪選時、週期、標籤、稍後再響、振動。
class AlarmEditSheet extends StatefulWidget {
  const AlarmEditSheet({super.key, required this.store, this.alarm});

  final ClockStore store;
  final Alarm? alarm;

  @override
  State<AlarmEditSheet> createState() => _AlarmEditSheetState();
}

class _AlarmEditSheetState extends State<AlarmEditSheet> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  late final TextEditingController _label;
  late Set<int> _weekdays;
  late int _snooze;
  late bool _vibrate;
  late int _hour;
  late int _minute;

  bool get isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final DateTime soon = DateTime.now().add(const Duration(minutes: 1));
    _hour = widget.alarm?.hour ?? soon.hour;
    _minute = widget.alarm?.minute ?? soon.minute;
    _weekdays = Set<int>.of(widget.alarm?.weekdays ?? const <int>{});
    _snooze = widget.alarm?.snoozeMinutes ?? 10;
    _vibrate = widget.alarm?.vibrate ?? true;
    _label = TextEditingController(text: widget.alarm?.label ?? '');
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Alarm alarm = Alarm(
      id: widget.alarm?.id ?? widget.store.newAlarmId(),
      hour: _hour,
      minute: _minute,
      weekdays: _weekdays,
      label: _label.text.trim(),
      enabled: true,
      snoozeMinutes: _snooze,
      vibrate: _vibrate,
    );
    await widget.store.upsertAlarm(alarm);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<String> chars = <String>[
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: p.hairline)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? l10n.editAlarm : l10n.addAlarm,
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 6),
                // 滾輪選時：中央帶以髮絲線標出。
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      top: InkWheel.itemExtent * 1.3,
                      left: 40,
                      right: 40,
                      child: Hairline(),
                    ),
                    Positioned(
                      top: InkWheel.itemExtent * 2.3,
                      left: 40,
                      right: 40,
                      child: Hairline(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        InkWheel(
                          itemCount: 24,
                          controller: _hourCtrl,
                          onChanged: (int v) => _hour = v,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 30,
                              color: p.faded,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        InkWheel(
                          itemCount: 60,
                          controller: _minuteCtrl,
                          onChanged: (int v) => _minute = v,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 週期快選。
                Row(
                  children: <Widget>[
                    _QuickRepeat(
                        label: l10n.once,
                        selected: _weekdays.isEmpty,
                        onTap: () => setState(() => _weekdays = <int>{})),
                    _QuickRepeat(
                        label: l10n.everyDay,
                        selected: _weekdays.length == 7,
                        onTap: () => setState(
                            () => _weekdays = <int>{1, 2, 3, 4, 5, 6, 7})),
                    _QuickRepeat(
                        label: l10n.workdays,
                        selected: _weekdays.length == 5 &&
                            _weekdays.containsAll(const <int>{1, 2, 3, 4, 5}),
                        onTap: () => setState(
                            () => _weekdays = <int>{1, 2, 3, 4, 5})),
                    _QuickRepeat(
                        label: l10n.weekends,
                        selected: _weekdays.length == 2 &&
                            _weekdays.containsAll(const <int>{6, 7}),
                        onTap: () =>
                            setState(() => _weekdays = <int>{6, 7})),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(7, (int i) {
                    final int day = i + 1;
                    final bool on = _weekdays.contains(day);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        if (on) {
                          _weekdays.remove(day);
                        } else {
                          _weekdays.add(day);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? p.ink : null,
                          border: on
                              ? null
                              : Border.all(color: p.hairline, width: 1.2),
                        ),
                        child: Text(
                          chars[i],
                          style: TextStyle(
                            fontSize: 14,
                            color: on ? p.paper : p.faded,
                            fontWeight:
                                on ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _label,
                  maxLength: 20,
                  style: TextStyle(
                      fontSize: 15, color: p.ink, letterSpacing: 1),
                  cursorColor: p.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: l10n.alarmLabelHint,
                    hintStyle: TextStyle(color: p.faded, letterSpacing: 1),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: p.hairline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: p.accent, width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.snoozeInterval,
                        style: TextStyle(
                          fontSize: 13.5,
                          letterSpacing: 1.5,
                          color: p.ink,
                        ),
                      ),
                    ),
                    for (final int m in <int>[5, 10, 15])
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _QuickRepeat(
                          label: l10n.minutesN(m),
                          selected: _snooze == m,
                          onTap: () => setState(() => _snooze = m),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.vibrate,
                        style: TextStyle(
                          fontSize: 13.5,
                          letterSpacing: 1.5,
                          color: p.ink,
                        ),
                      ),
                    ),
                    InkSwitch(
                      value: _vibrate,
                      onChanged: (bool v) => setState(() => _vibrate = v),
                    ),
                  ],
                ),
                if (isEditing && widget.alarm!.weekdays.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.skipNext,
                          style: TextStyle(
                            fontSize: 13.5,
                            letterSpacing: 1.5,
                            color: p.ink,
                          ),
                        ),
                      ),
                      InkSwitch(
                        value: widget.alarm!.skippedUntil != null,
                        onChanged: (bool v) async {
                          await widget.store
                              .setSkipNext(widget.alarm!.id, v);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    if (isEditing)
                      InkPill(
                        label: l10n.delete,
                        compact: true,
                        onTap: () async {
                          await widget.store.deleteAlarm(widget.alarm!.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    const Spacer(),
                    InkPill(
                      label: l10n.cancel,
                      compact: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    InkPill(
                      label: l10n.save,
                      compact: true,
                      filled: true,
                      onTap: _save,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickRepeat extends StatelessWidget {
  const _QuickRepeat({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 1,
                color: selected ? p.accent : p.faded,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 14,
              height: 2,
              color: selected ? p.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
