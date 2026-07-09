import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../util/format.dart';
import '../widgets/ink_kit.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key, required this.store});

  final ClockStore store;

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage>
    with SingleTickerProviderStateMixin {
  Ticker? _frame;

  @override
  void initState() {
    super.initState();
    // 碼錶跑動時逐幀刷新百分秒；停下時不耗一幀。
    _frame = createTicker((_) => setState(() {}));
    widget.store.addListener(_syncTicker);
    _syncTicker();
  }

  void _syncTicker() {
    final Ticker? t = _frame;
    if (t == null) return;
    if (widget.store.swRunning && !t.isActive) {
      t.start();
    } else if (!widget.store.swRunning && t.isActive) {
      t.stop();
    }
    // 任何狀態變更（含暫停時按歸零）都要立即反映在畫面上。
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncTicker);
    _frame?.dispose();
    _frame = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ClockStore store = widget.store;
    final DateTime now = DateTime.now();
    final Duration elapsed = store.swElapsed(now);
    final bool running = store.swRunning;
    final bool hasContent = running || elapsed > Duration.zero;
    final List<Duration> laps = store.swLaps;

    // 計次分段：本次 - 上次；找最快最慢。
    final List<Duration> segments = <Duration>[];
    for (int i = 0; i < laps.length; i++) {
      segments.add(i == 0 ? laps[i] : laps[i] - laps[i - 1]);
    }
    int fastest = -1;
    int slowest = -1;
    if (segments.length >= 2) {
      for (int i = 0; i < segments.length; i++) {
        if (fastest < 0 || segments[i] < segments[fastest]) fastest = i;
        if (slowest < 0 || segments[i] > segments[slowest]) slowest = i;
      }
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.tabStopwatch,
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          formatStopwatch(elapsed),
          style: TextStyle(
            fontSize: 58,
            height: 1,
            fontWeight: FontWeight.w200,
            letterSpacing: 1,
            color: p.ink,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (!hasContent)
          Text(
            l10n.stopwatchHint,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.5,
              color: p.faded,
            ),
          ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkPill(
              label: running ? l10n.lap : l10n.reset,
              onTap: !hasContent
                  ? null
                  : running
                      ? store.swLap
                      : store.swReset,
            ),
            const SizedBox(width: 14),
            InkPill(
              label: running
                  ? l10n.pause
                  : hasContent
                      ? l10n.resume
                      : l10n.start,
              filled: true,
              onTap: running ? store.swPause : store.swStart,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 3,
          child: laps.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                  itemCount: segments.length,
                  separatorBuilder: (_, _) => const Hairline(),
                  itemBuilder: (BuildContext context, int index) {
                    // 最新的排最上面。
                    final int i = segments.length - 1 - index;
                    final bool isFastest = i == fastest;
                    final bool isSlowest = i == slowest;
                    final Color color = isFastest
                        ? p.accent
                        : isSlowest
                            ? p.faded
                            : p.ink;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: <Widget>[
                          Text(
                            l10n.lapN(i + 1),
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 1,
                              color: p.faded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isFastest || isSlowest)
                            Text(
                              isFastest ? l10n.fastest : l10n.slowest,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                color: color,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            formatStopwatch(segments[i]),
                            style: TextStyle(
                              fontSize: 16,
                              color: color,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Text(
                            formatStopwatch(laps[i]),
                            style: TextStyle(
                              fontSize: 16,
                              color: p.faded,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
