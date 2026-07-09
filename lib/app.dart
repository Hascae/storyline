import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/alarm.dart';
import 'services/alarm_ringer.dart';
import 'services/clock_store.dart';
import 'services/notification_service.dart';
import 'theme/chapter.dart';
import 'ui/alarm_ring_page.dart';
import 'ui/home_shell.dart';

class MonogatariApp extends StatefulWidget {
  const MonogatariApp({
    super.key,
    required this.store,
    required this.notifications,
    required this.ringer,
  });

  final ClockStore store;
  final NotificationService notifications;
  final AlarmRinger ringer;

  @override
  State<MonogatariApp> createState() => _MonogatariAppState();
}

class _MonogatariAppState extends State<MonogatariApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  late Chapter _chapter;
  Timer? _chapterTicker;
  bool _ringOpen = false;

  @override
  void initState() {
    super.initState();
    _chapter = chapterOf(DateTime.now());
    // 章節（配色）隨時辰流轉，低頻檢查即可。
    _chapterTicker = Timer.periodic(const Duration(seconds: 20), (_) {
      final Chapter next = chapterOf(DateTime.now());
      if (next != _chapter) setState(() => _chapter = next);
    });
    // 響鈴（含全屏意圖冷啟動補發）一律導向響鈴頁。
    widget.ringer.onRing = _openRingById;
  }

  @override
  void dispose() {
    _chapterTicker?.cancel();
    super.dispose();
  }

  void _openRingById(int alarmId) {
    final Alarm? alarm = widget.store.alarmById(alarmId);
    if (alarm != null) openRing(alarm);
  }

  /// 打開響鈴頁（去重，避免同時疊多層）。
  void openRing(Alarm alarm) {
    if (_ringOpen) return;
    final NavigatorState? nav = _navigator.currentState;
    if (nav == null) {
      // 首幀尚未建立導航器時延後到下一幀。
      WidgetsBinding.instance.addPostFrameCallback((_) => openRing(alarm));
      return;
    }
    _ringOpen = true;
    nav
        .push(MaterialPageRoute<void>(
      builder: (_) => AlarmRingPage(alarm: alarm, store: widget.store),
      fullscreenDialog: true,
    ))
        .whenComplete(() => _ringOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette palette = paletteOf(_chapter);
    return MaterialApp(
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,
      theme: themeFor(palette),
      // 語言完全跟隨系統：簡體地區得簡體，繁體地區（含台港澳）得繁體。
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback:
          (Locale? device, Iterable<Locale> supported) {
        if (device != null && device.languageCode == 'zh') {
          final bool traditional = device.scriptCode == 'Hant' ||
              device.countryCode == 'TW' ||
              device.countryCode == 'HK' ||
              device.countryCode == 'MO';
          if (traditional) {
            return const Locale.fromSubtags(
                languageCode: 'zh', scriptCode: 'Hant');
          }
          return const Locale('zh');
        }
        // 非中文系統：以簡體為底。
        return const Locale('zh');
      },
      builder: (BuildContext context, Widget? child) {
        return ChapterTheme(
          chapter: _chapter,
          palette: palette,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeShell(
        store: widget.store,
        notifications: widget.notifications,
      ),
    );
  }
}
