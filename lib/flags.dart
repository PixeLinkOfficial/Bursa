import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum FlagCode { us, eu, iq }

class Currency {
  const Currency(this.flag, this.name, this.code);
  final FlagCode flag;
  final String name;
  final String code;

  static const usd = Currency(FlagCode.us, 'دولار أمريكي', 'USD');
  static const eur = Currency(FlagCode.eu, 'يورو', 'EUR');
  static const iqd = Currency(FlagCode.iq, 'دينار عراقي', 'IQD');
}

/// Flags are drawn in code (3:2) so they stay sharp on any TV and need no
/// image files or internet.
class FlagIcon extends StatelessWidget {
  const FlagIcon(this.code, {super.key, required this.height});

  final FlagCode code;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height * 0.12);
    return SizedBox(
      width: height * 1.5,
      height: height,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CustomPaint(painter: _FlagPainter(code)),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.code);

  final FlagCode code;

  // All flags are drawn on a 30 x 20 grid and scaled to the widget size.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 20);
    switch (code) {
      case FlagCode.us:
        _us(canvas);
      case FlagCode.eu:
        _eu(canvas);
      case FlagCode.iq:
        _iq(canvas);
    }
    canvas.restore();
  }

  static Path _star(double cx, double cy, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.382;
      final a = -math.pi / 2 + i * math.pi / 5;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    return p..close();
  }

  void _us(Canvas c) {
    const stripe = 20 / 13;
    final red = Paint()..color = const Color(0xFFB22234);
    final white = Paint()..color = Colors.white;
    for (var i = 0; i < 13; i++) {
      c.drawRect(Rect.fromLTWH(0, i * stripe, 30, stripe + 0.03), i.isEven ? red : white);
    }
    const cw = 12.0;
    const ch = stripe * 7;
    c.drawRect(const Rect.fromLTWH(0, 0, cw, ch), Paint()..color = const Color(0xFF3C3B6E));
    for (var row = 0; row < 9; row++) {
      final n = row.isOdd ? 5 : 6;
      for (var j = 0; j < n; j++) {
        final x = (row.isOdd ? (2 * j + 2) : (2 * j + 1)) * cw / 12;
        final y = (row + 1) * ch / 10;
        c.drawPath(_star(x, y, 0.55), white);
      }
    }
  }

  void _eu(Canvas c) {
    c.drawRect(const Rect.fromLTWH(0, 0, 30, 20), Paint()..color = const Color(0xFF003399));
    final gold = Paint()..color = const Color(0xFFFFCC00);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawPath(_star(15 + 6.67 * math.sin(a), 10 - 6.67 * math.cos(a), 1.11), gold);
    }
  }

  void _iq(Canvas c) {
    const third = 20 / 3;
    c.drawRect(const Rect.fromLTWH(0, 0, 30, third + 0.03), Paint()..color = const Color(0xFFCE1126));
    c.drawRect(const Rect.fromLTWH(0, third, 30, third + 0.03), Paint()..color = Colors.white);
    c.drawRect(const Rect.fromLTWH(0, third * 2, 30, third), Paint()..color = Colors.black);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'الله أكبر',
        style: TextStyle(
          fontFamily: kFont,
          fontSize: 4.6,
          fontWeight: FontWeight.w700,
          color: Color(0xFF007A3D),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(c, Offset(15 - tp.width / 2, 10 - tp.height / 2));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.code != code;
}
