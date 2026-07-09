import 'package:flutter/material.dart';

/// 一天被讀成四個章節：晨、晝、暮、夜。
/// 介面的紙色、墨色與朱色都隨章節流轉 —— 這是「物語」的骨架。
enum Chapter { dawn, day, dusk, night }

Chapter chapterOf(DateTime time) {
  final int h = time.hour;
  if (h >= 5 && h < 9) return Chapter.dawn;
  if (h >= 9 && h < 17) return Chapter.day;
  if (h >= 17 && h < 20) return Chapter.dusk;
  return Chapter.night;
}

/// 取自日本傳統色：生成り（紙）、墨、朱、藍、茜。
class ChapterPalette {
  const ChapterPalette({
    required this.paper,
    required this.ink,
    required this.faded,
    required this.accent,
    required this.hairline,
    required this.recessed,
    required this.isDark,
  });

  /// 底色 —— 紙。
  final Color paper;

  /// 主文字 —— 墨。
  final Color ink;

  /// 次要文字 —— 薄墨。
  final Color faded;

  /// 強調 —— 朱。
  final Color accent;

  /// 髮絲線。
  final Color hairline;

  /// 微凹面（輸入框、滑輪選中帶）。
  final Color recessed;

  final bool isDark;

  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;
}

const ChapterPalette _dawn = ChapterPalette(
  paper: Color(0xFFF4EEE3),
  ink: Color(0xFF34313A),
  faded: Color(0xFF97907E),
  accent: Color(0xFFCE4F2C),
  hairline: Color(0xFFE2DAC7),
  recessed: Color(0xFFECE5D6),
  isDark: false,
);

const ChapterPalette _day = ChapterPalette(
  paper: Color(0xFFF8F5EC),
  ink: Color(0xFF27262E),
  faded: Color(0xFF8C8674),
  accent: Color(0xFFC94D2B),
  hairline: Color(0xFFE7E1D0),
  recessed: Color(0xFFF0EBDE),
  isDark: false,
);

const ChapterPalette _dusk = ChapterPalette(
  paper: Color(0xFF262029),
  ink: Color(0xFFEFE9DB),
  faded: Color(0xFF95899A),
  accent: Color(0xFFE06A45),
  hairline: Color(0xFF382F3C),
  recessed: Color(0xFF2E2732),
  isDark: true,
);

const ChapterPalette _night = ChapterPalette(
  paper: Color(0xFF15161C),
  ink: Color(0xFFE8E5DA),
  faded: Color(0xFF7B7C86),
  accent: Color(0xFFE25A3B),
  hairline: Color(0xFF262830),
  recessed: Color(0xFF1C1E26),
  isDark: true,
);

ChapterPalette paletteOf(Chapter chapter) {
  switch (chapter) {
    case Chapter.dawn:
      return _dawn;
    case Chapter.day:
      return _day;
    case Chapter.dusk:
      return _dusk;
    case Chapter.night:
      return _night;
  }
}

/// 以 InheritedWidget 向整棵樹提供當前章節配色。
class ChapterTheme extends InheritedWidget {
  const ChapterTheme({
    super.key,
    required this.chapter,
    required this.palette,
    required super.child,
  });

  final Chapter chapter;
  final ChapterPalette palette;

  static ChapterTheme of(BuildContext context) {
    final ChapterTheme? theme =
        context.dependOnInheritedWidgetOfExactType<ChapterTheme>();
    assert(theme != null, 'ChapterTheme not found in widget tree');
    return theme!;
  }

  @override
  bool updateShouldNotify(ChapterTheme oldWidget) =>
      oldWidget.chapter != chapter;
}

/// 供 MaterialApp 使用的基礎 ThemeData —— 只鋪底，細節由自繪部件完成。
ThemeData themeFor(ChapterPalette p) {
  final ColorScheme scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.isDark ? const Color(0xFF15161C) : const Color(0xFFF8F5EC),
    secondary: p.faded,
    onSecondary: p.paper,
    error: p.accent,
    onError: p.paper,
    surface: p.paper,
    onSurface: p.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    fontFamilyFallback: const <String>[
      'PingFang SC',
      'PingFang TC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
      'Source Han Sans SC',
      'sans-serif',
    ],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.25),
      selectionHandleColor: p.accent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
