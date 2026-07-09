import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 全套介面圖標皆為手寫路徑，一筆一畫自繪，不取用任何系統圖標。
/// 統一 24×24 座標系、圓頭筆鋒，帶一點手繪的鬆動。
enum Glyph {
  clock,
  bell,
  sandglass,
  stopwatch,
  plus,
  sun,
  moon,
  chevronLeft,
  close,
  check,
}

class InkGlyph extends StatelessWidget {
  const InkGlyph(
    this.glyph, {
    super.key,
    this.size = 24,
    required this.color,
    this.strokeWidth = 1.7,
  });

  final Glyph glyph;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(glyph, color, strokeWidth),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.strokeWidth);

  final Glyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    canvas.scale(s);
    final Paint pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s * s // 已隨座標縮放
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint dot = Paint()..color = color;

    switch (glyph) {
      case Glyph.clock:
        canvas.drawCircle(const Offset(12, 12), 8.6, pen);
        canvas.drawLine(const Offset(12, 12), const Offset(12, 6.8), pen);
        canvas.drawLine(const Offset(12, 12), const Offset(15.8, 13.6), pen);
        break;
      case Glyph.bell:
        final Path body = Path()
          ..moveTo(5.4, 17)
          ..lineTo(18.6, 17)
          ..lineTo(17.2, 14.8)
          ..lineTo(17.2, 10.4)
          ..arcTo(const Rect.fromLTRB(6.8, 5.2, 17.2, 15.6), 0, -math.pi,
              false)
          ..lineTo(6.8, 14.8)
          ..close();
        canvas.drawPath(body, pen);
        canvas.drawLine(const Offset(12, 5.2), const Offset(12, 3.6), pen);
        canvas.drawArc(
            const Rect.fromLTRB(10, 17.6, 14, 21.2), 0.35, math.pi - 0.7,
            false, pen);
        break;
      case Glyph.sandglass:
        final Path glass = Path()
          ..moveTo(7, 4.4)
          ..lineTo(17, 4.4)
          ..lineTo(17, 7.4)
          ..lineTo(13, 12)
          ..lineTo(17, 16.6)
          ..lineTo(17, 19.6)
          ..lineTo(7, 19.6)
          ..lineTo(7, 16.6)
          ..lineTo(11, 12)
          ..lineTo(7, 7.4)
          ..close();
        canvas.drawPath(glass, pen);
        canvas.drawCircle(const Offset(12, 17), 1.1, dot);
        break;
      case Glyph.stopwatch:
        canvas.drawCircle(const Offset(12, 13.4), 7.4, pen);
        canvas.drawLine(const Offset(10.2, 3.6), const Offset(13.8, 3.6), pen);
        canvas.drawLine(const Offset(12, 3.6), const Offset(12, 6), pen);
        canvas.drawLine(const Offset(12, 13.4), const Offset(14.8, 10.6), pen);
        break;
      case Glyph.plus:
        canvas.drawLine(const Offset(12, 5.5), const Offset(12, 18.5), pen);
        canvas.drawLine(const Offset(5.5, 12), const Offset(18.5, 12), pen);
        break;
      case Glyph.sun:
        canvas.drawCircle(const Offset(12, 12), 4.6, pen);
        for (int i = 0; i < 8; i++) {
          final double a = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + math.cos(a) * 7.2, 12 + math.sin(a) * 7.2),
            Offset(12 + math.cos(a) * 9.2, 12 + math.sin(a) * 9.2),
            pen,
          );
        }
        break;
      case Glyph.moon:
        final Path moon = Path()
          ..moveTo(14.5, 4.8)
          ..arcTo(const Rect.fromLTRB(4.6, 4.6, 19.4, 19.4), -math.pi / 2.6,
              math.pi * 1.52, false)
          ..arcTo(const Rect.fromLTRB(7.8, 3.4, 20.6, 16.2), math.pi * 0.78,
              -math.pi * 1.02, false);
        canvas.drawPath(moon, pen);
        break;
      case Glyph.chevronLeft:
        final Path chev = Path()
          ..moveTo(14.6, 5.8)
          ..lineTo(8.8, 12)
          ..lineTo(14.6, 18.2);
        canvas.drawPath(chev, pen);
        break;
      case Glyph.close:
        canvas.drawLine(const Offset(6.6, 6.6), const Offset(17.4, 17.4), pen);
        canvas.drawLine(const Offset(17.4, 6.6), const Offset(6.6, 17.4), pen);
        break;
      case Glyph.check:
        final Path check = Path()
          ..moveTo(5.8, 12.6)
          ..lineTo(10.2, 17)
          ..lineTo(18.2, 7.4);
        canvas.drawPath(check, pen);
        break;
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
