import 'package:flutter/material.dart';

import '../theme/chapter.dart';

/// 髮絲分隔線。
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: p.hairline),
      ),
    );
  }
}

/// 墨色開關：細邊、圓珠，開啟時滾向朱色。
class InkSwitch extends StatelessWidget {
  const InkSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 27,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? p.accent : p.hairline,
            width: 1.4,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? p.accent : p.faded.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// 墨線藥丸按鈕；filled 時以朱色落墨。
class InkPill extends StatelessWidget {
  const InkPill({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final bool enabled = onTap != null;
    final Color fg = filled
        ? p.paper
        : enabled
            ? p.ink
            : p.faded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
        decoration: BoxDecoration(
          color: filled ? p.accent : null,
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(
                  color: enabled ? p.faded.withValues(alpha: 0.6) : p.hairline,
                  width: 1.2,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: compact ? 13.5 : 15,
            height: 1.2,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 落款印章：一方朱印，蓋著「物」字，帶一點手蓋的偏斜。
class Seal extends StatelessWidget {
  const Seal({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(size * 0.18),
        ),
        child: Text(
          '物',
          style: TextStyle(
            color: p.paper,
            fontSize: size * 0.62,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 縱書章節籤：如和書側標，一字一格，末端垂一條細線。
class ChapterTag extends StatelessWidget {
  const ChapterTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String ch in text.split(''))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              ch,
              style: TextStyle(
                color: p.faded,
                fontSize: 13,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(width: 1, height: 34, color: p.hairline),
      ],
    );
  }
}

/// 滾輪選擇器（時、分、秒共用）。
class InkWheel extends StatelessWidget {
  const InkWheel({
    super.key,
    required this.itemCount,
    required this.controller,
    required this.onChanged,
    this.width = 76,
    this.loop = true,
  });

  final int itemCount;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final double width;
  final bool loop;

  static const double itemExtent = 46;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final Widget wheel = ListWheelScrollView.useDelegate(
      controller: controller,
      physics: const FixedExtentScrollPhysics(),
      itemExtent: itemExtent,
      perspective: 0.0025,
      diameterRatio: 1.6,
      onSelectedItemChanged: onChanged,
      childDelegate: loop
          ? ListWheelChildLoopingListDelegate(children: _items(p))
          : ListWheelChildListDelegate(children: _items(p)),
    );
    return SizedBox(width: width, height: itemExtent * 3.6, child: wheel);
  }

  List<Widget> _items(ChapterPalette p) {
    return List<Widget>.generate(itemCount, (int i) {
      return Center(
        child: _WheelDigit(
          value: i,
          controller: controller,
          index: i,
          itemCount: itemCount,
          palette: p,
        ),
      );
    });
  }
}

class _WheelDigit extends StatelessWidget {
  const _WheelDigit({
    required this.value,
    required this.controller,
    required this.index,
    required this.itemCount,
    required this.palette,
  });

  final int value;
  final FixedExtentScrollController controller;
  final int index;
  final int itemCount;
  final ChapterPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        int selected = index;
        if (controller.hasClients && controller.positions.isNotEmpty) {
          selected = controller.selectedItem % itemCount;
          if (selected < 0) selected += itemCount;
        } else {
          selected = controller.initialItem % itemCount;
        }
        final bool isSelected = selected == index;
        return Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: isSelected ? 34 : 26,
            height: 1,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
            color: isSelected ? palette.ink : palette.faded,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
