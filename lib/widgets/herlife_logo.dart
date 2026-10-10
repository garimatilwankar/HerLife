import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';

/// Vector CustomPainter for HerLife geometric HL monogram logo ("The Precision Prisms").
class HerLifeLogoPainter extends CustomPainter {
  final Color leftStemColor;
  final Color rightLColor;
  final Color crossbarColor;

  HerLifeLogoPainter({
    this.leftStemColor = kWine,
    this.rightLColor = kWine,
    this.crossbarColor = kBlush,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stemW = w * 0.18;
    final r = Radius.circular(stemW / 2.0);

    final leftX = w * 0.22;
    final rightX = w * 0.52;

    final topY = h * 0.18;
    final bottomY = h * 0.82;
    final footX = w * 0.80;

    final crossY = h * 0.48;
    final crossH = h * 0.16;
    final crossR = Radius.circular(crossH / 2.0);
    final crossLeft = w * 0.14;
    final crossRight = w * 0.68;

    final paintLeft = Paint()
      ..color = leftStemColor
      ..style = PaintingStyle.fill;

    final paintRight = Paint()
      ..color = rightLColor
      ..style = PaintingStyle.fill;

    final paintCross = Paint()
      ..color = crossbarColor
      ..style = PaintingStyle.fill;

    // 1. Left Stem (Vertical Capsule)
    final leftRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(leftX, topY, leftX + stemW, bottomY),
      r,
    );
    canvas.drawRRect(leftRRect, paintLeft);

    // 2. Right 'L' Element (Vertical stem + Horizontal foot)
    final rightRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(rightX, topY, rightX + stemW, bottomY),
      r,
    );
    canvas.drawRRect(rightRRect, paintRight);

    final footRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(rightX, bottomY - stemW, footX, bottomY),
      r,
    );
    canvas.drawRRect(footRRect, paintRight);

    // 3. Interlocking Horizontal Crossbar (Pill Capsule)
    final crossRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(crossLeft, crossY, crossRight, crossY + crossH),
      crossR,
    );
    canvas.drawRRect(crossRRect, paintCross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Symbol-only geometric HL mark widget.
class HerLifeLogoMark extends StatelessWidget {
  final double size;
  final Color? leftStemColor;
  final Color? rightLColor;
  final Color? crossbarColor;
  final bool hasBackground;
  final Color? backgroundColor;
  final double borderRadius;

  const HerLifeLogoMark({
    super.key,
    this.size = 48,
    this.leftStemColor,
    this.rightLColor,
    this.crossbarColor,
    this.hasBackground = false,
    this.backgroundColor,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? kWine;

    // Colors matching the reference image light / dark display
    final cLeft = leftStemColor ?? (hasBackground ? const Color(0xFFFBF9F6) : kWine);
    final cRight = rightLColor ?? (hasBackground ? const Color(0xFFE598AC) : kWine);
    final cCross = crossbarColor ?? (hasBackground ? kWine : const Color(0xFFE598AC));

    final painter = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HerLifeLogoPainter(
          leftStemColor: cLeft,
          rightLColor: cRight,
          crossbarColor: cCross,
        ),
      ),
    );

    if (!hasBackground) return painter;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: painter),
    );
  }
}

/// Full brand logo combining Geometric HL mark + 'HerLife' wordmark.
class HerLifeBrandLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Axis direction;
  final Color textColor;
  final bool hasBackgroundIcon;

  const HerLifeBrandLogo({
    super.key,
    double? markSize,
    double? iconSize,
    this.fontSize = 24,
    this.direction = Axis.horizontal,
    this.textColor = kWine,
    this.hasBackgroundIcon = true,
  }) : iconSize = markSize ?? iconSize ?? 44;

  @override
  Widget build(BuildContext context) {
    final mark = HerLifeLogoMark(
      size: iconSize,
      hasBackground: hasBackgroundIcon,
    );

    final wordmark = Text(
      'HerLife',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
    );

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: fontSize * 0.4),
          wordmark,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: 12),
        wordmark,
      ],
    );
  }
}
