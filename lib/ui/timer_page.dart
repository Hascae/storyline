import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_timer.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../util/format.dart';
import '../widgets/ink_glyphs.dart';
import '../widgets/ink_kit.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.store});

  final ClockStore store;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  static const List<Duration> _presets = <Duration>[
    Duration(minutes: 1),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 25),
    Duration(hours: 1),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final DateTime now = DateTime.now();
      bool finishedNow = false;
      for (final AppTimer t in widget.store.timers) {
        if (t.phase == TimerPhase.running &&
            t.remaining(now) == Duration.zero) {
          finishedNow = true;
        }
      }
      if (finishedNow) widget.store.tick(now);
      if (now.second != _now.second || finishedNow) {
        if (mounted) setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openNewTimer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTimerSheet(store: widget.store),
    );
  }

  String _presetLabel(AppLocalizations l10n, Duration d) {
    if (d.inHours >= 1) return '${d.inHours} ${l10n.hourUnit}';
    return '${d.inMinutes} ${l10n.minuteUnit}';
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (BuildContext context, _) {
        final List<AppTimer> timers = widget.store.timers;
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.timerTitle,
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
                      onTap: _openNewTimer,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: InkGlyph(Glyph.plus, size: 24, color: p.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (timers.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.noTimers,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.8,
                          letterSpacing: 1.5,
                          color: p.faded,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          for (final Duration d in _presets)
                            InkPill(
                              label: _presetLabel(l10n, d),
                              compact: true,
                              onTap: () => widget.store.addTimer(d, ''),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: timers.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Hairline(),
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _TimerRow(
                    timer: timers[index],
                    now: _now,
                    store: widget.store,
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

class _TimerRow extends StatelessWidget {
  const _TimerRow({
    required this.timer,
    required this.now,
    required this.store,
  });

  final AppTimer timer;
  final DateTime now;
  final ClockStore store;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Duration left = timer.remaining(now);
    final bool finished = timer.phase == TimerPhase.finished;
    final bool running = timer.phase == TimerPhase.running;
    final double progress = timer.total.inMilliseconds == 0
        ? 0
        : 1 - left.inMilliseconds / timer.total.inMilliseconds;

    return Dismissible(
      key: ValueKey<int>(timer.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => store.removeTimer(timer.id),
      background: Container(
        color: p.accent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Text(
          l10n.delete,
          style: TextStyle(color: p.paper, letterSpacing: 2, fontSize: 14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        finished ? l10n.timerDone : formatCountdown(left),
                        style: TextStyle(
                          fontSize: finished ? 26 : 38,
                          height: 1.1,
                          fontWeight:
                              finished ? FontWeight.w500 : FontWeight.w300,
                          letterSpacing: 1,
                          color: finished ? p.accent : p.ink,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        timer.label.isEmpty
                            ? formatCountdown(timer.total)
                            : '${timer.label} · ${formatCountdown(timer.total)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          letterSpacing: 1,
                          color: p.faded,
                        ),
                      ),
                    ],
                  ),
                ),
                if (finished)
                  InkPill(
                    label: l10n.reset,
                    compact: true,
                    filled: true,
                    onTap: () => store.resetTimer(timer.id),
                  )
                else ...<Widget>[
                  InkPill(
                    label: l10n.plusOneMinute,
                    compact: true,
                    onTap: () => store.extendTimer(
                        timer.id, const Duration(minutes: 1)),
                  ),
                  const SizedBox(width: 8),
                  InkPill(
                    label: running
                        ? l10n.pause
                        : timer.phase == TimerPhase.paused
                            ? l10n.resume
                            : l10n.start,
                    compact: true,
                    filled: true,
                    onTap: () {
                      if (running) {
                        store.pauseTimer(timer.id);
                      } else if (timer.phase == TimerPhase.paused) {
                        store.resumeTimer(timer.id);
                      } else {
                        store.restartTimer(timer.id);
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // 一條細線的進度：朱色慢慢走完這一段。
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2.4,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: ColoredBox(color: p.hairline)),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: ColoredBox(color: p.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTimerSheet extends StatefulWidget {
  const _NewTimerSheet({required this.store});

  final ClockStore store;

  @override
  State<_NewTimerSheet> createState() => _NewTimerSheetState();
}

class _NewTimerSheetState extends State<_NewTimerSheet> {
  final FixedExtentScrollController _h =
      FixedExtentScrollController(initialItem: 0);
  final FixedExtentScrollController _m =
      FixedExtentScrollController(initialItem: 5);
  final FixedExtentScrollController _s =
      FixedExtentScrollController(initialItem: 0);
  late final TextEditingController _label = TextEditingController();
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    _s.dispose();
    _label.dispose();
    super.dispose();
  }

  Duration get _total => Duration(
      hours: _hours, minutes: _minutes, seconds: _seconds);

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    Widget unit(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: p.faded, letterSpacing: 1),
          ),
        );

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
                  l10n.newTimer,
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      top: InkWheel.itemExtent * 1.3,
                      left: 30,
                      right: 30,
                      child: Hairline(),
                    ),
                    Positioned(
                      top: InkWheel.itemExtent * 2.3,
                      left: 30,
                      right: 30,
                      child: Hairline(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        InkWheel(
                          itemCount: 24,
                          width: 64,
                          controller: _h,
                          onChanged: (int v) =>
                              setState(() => _hours = v),
                        ),
                        unit(l10n.hourUnit),
                        InkWheel(
                          itemCount: 60,
                          width: 64,
                          controller: _m,
                          onChanged: (int v) =>
                              setState(() => _minutes = v),
                        ),
                        unit(l10n.minuteUnit),
                        InkWheel(
                          itemCount: 60,
                          width: 64,
                          controller: _s,
                          onChanged: (int v) =>
                              setState(() => _seconds = v),
                        ),
                        unit(l10n.secondUnit),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _label,
                  maxLength: 20,
                  style: TextStyle(
                      fontSize: 15, color: p.ink, letterSpacing: 1),
                  cursorColor: p.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: l10n.timerLabelHint,
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
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    InkPill(
                      label: l10n.cancel,
                      compact: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    InkPill(
                      label: l10n.start,
                      compact: true,
                      filled: true,
                      onTap: _total == Duration.zero
                          ? null
                          : () async {
                              await widget.store
                                  .addTimer(_total, _label.text.trim());
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
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
