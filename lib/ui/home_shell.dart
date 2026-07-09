import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/clock_store.dart';
import '../services/notification_service.dart';
import '../theme/chapter.dart';
import '../widgets/ink_glyphs.dart';
import 'alarm_page.dart';
import 'clock_page.dart';
import 'stopwatch_page.dart';
import 'timer_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.store,
    required this.notifications,
  });

  final ClockStore store;
  final NotificationService notifications;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 授權一律由系統彈窗完成，應用啟動後直接發起，不設任何介面按鈕。
    // 同時在語言解析完成後，把啟用中的鬧鐘重新掛回系統：
    // 應用更新、資料還原、個別 ROM 清理之後依然可靠。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.notifications.requestPermissions();
      if (!mounted) return;
      _syncNotificationStrings(AppLocalizations.of(context)!);
      await widget.store.rearmAll();
    });
    // 響鈴偵測交由響鈴核心的事件流；這裡只做週期對賬。
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      widget.store.tick(DateTime.now());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.tick(DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _syncNotificationStrings(AppLocalizations l10n) {
    final NotificationStrings s = widget.notifications.strings;
    s.alarmDefaultTitle = l10n.alarmDefaultName;
    s.alarmBody = l10n.alarmNotifBody;
    s.snoozeAction = l10n.snooze;
    s.stopAction = l10n.stopAlarm;
    s.timerDoneTitle = l10n.timerDone;
    s.timerDoneBody = l10n.timerNotifBodyPlain;
    s.timerChannelName = l10n.timerTitle;
    s.timerChannelDescription = l10n.timerDone;
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    _syncNotificationStrings(l10n);

    final List<(Glyph, String)> tabs = <(Glyph, String)>[
      (Glyph.clock, l10n.tabClock),
      (Glyph.bell, l10n.tabAlarm),
      (Glyph.sandglass, l10n.tabTimer),
      (Glyph.stopwatch, l10n.tabStopwatch),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          color: p.paper,
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab,
              children: <Widget>[
                ClockPage(store: widget.store),
                AlarmPage(store: widget.store),
                TimerPage(store: widget.store),
                StopwatchPage(store: widget.store),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ColoredBox(
          color: p.paper,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 1, child: ColoredBox(color: p.hairline)),
                SizedBox(
                  height: 64,
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            glyph: tabs[i].$1,
                            label: tabs[i].$2,
                            active: _tab == i,
                            onTap: () => setState(() => _tab = i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.glyph,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Glyph glyph;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final Color color = active ? p.ink : p.faded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          InkGlyph(glyph, size: 23, color: color,
              strokeWidth: active ? 1.9 : 1.6),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              height: 1,
              letterSpacing: 2,
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? p.accent : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
