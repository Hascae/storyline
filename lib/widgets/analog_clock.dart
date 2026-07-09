import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/chapter.dart';

/// 主錶盤：一圈細墨線、十二點墨點、朱色秒針。
/// 沒有數字、沒有裝飾 —— 留白即是設計。
class AnalogClock extends StatelessWidget {
  const AnalogClock({super.key, required this.time, this.size = 232});

  final DateTime time;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _DialPainter(time, p),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter(this.time, this.p);

  final DateTime time;
  final ChapterPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2;

    final Paint ring = Paint()
      ..color = p.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r - 1, ring);

    // 時標：四正稍大，其餘為淡墨小點。
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6 - math.pi / 2;
      final bool cardinal = i % 3 == 0;
      final Paint markPaint = Paint()
        ..color = cardinal ? p.ink : p.faded.withValues(alpha: 0.55);
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (r - 14),
        cardinal ? 2.2 : 1.3,
        markPaint,
      );
    }

    final double secF = time.second + time.millisecond / 1000;
    final double minF = time.minute + secF / 60;
    final double hourF = time.hour % 12 + minF / 60;

    void hand(double turns, double length, double width, Color color,
        {double tail = 0}) {
      final double a = turns * 2 * math.pi - math.pi / 2;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      final Paint pen = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c - dir * tail, c + dir * length, pen);
    }

    hand(hourF / 12, r * 0.48, 3.4, p.ink);
    hand(minF / 60, r * 0.70, 2.4, p.ink);
    hand(secF / 60, r * 0.78, 1.2, p.accent, tail: r * 0.14);

    canvas.drawCircle(c, 3.4, Paint()..color = p.accent);
    canvas.drawCircle(c, 1.4, Paint()..color = p.paper);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.p != p;
}
