import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Minh họa vector (CustomPaint) — không cần asset ảnh, scale mọi màn hình.
enum AppIllustrationKind {
  heroHome,
  authWelcome,
  wizardBlock,
  wizardScores,
  wizardInterests,
  wizardStrengths,
  wizardRegion,
  wizardResults,
  charts,
  chat,
  forum,
  emptyState,
}

class AppIllustration extends StatelessWidget {
  final AppIllustrationKind kind;
  final double size;
  final Color? primary;
  final Color? secondary;

  const AppIllustration({
    super.key,
    required this.kind,
    this.size = 140,
    this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(
          kind: kind,
          primary: primary ?? AppColors.primary,
          secondary: secondary ?? AppColors.secondary,
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final AppIllustrationKind kind;
  final Color primary;
  final Color secondary;

  _IllustrationPainter({
    required this.kind,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;

    // Nền mờ trang trí
    final bg = Paint()
      ..color = primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r * 1.15, bg);
    canvas.drawCircle(
      Offset(c.dx + r * 0.55, c.dy - r * 0.35),
      r * 0.35,
      Paint()..color = secondary.withValues(alpha: 0.12),
    );

    switch (kind) {
      case AppIllustrationKind.heroHome:
        _drawGraduation(canvas, c, r, primary, secondary);
        _drawBook(canvas, Offset(c.dx - r * 0.55, c.dy + r * 0.2), r * 0.45);
        break;
      case AppIllustrationKind.authWelcome:
        _drawGraduation(canvas, c, r * 0.9, primary, secondary);
        break;
      case AppIllustrationKind.wizardBlock:
        _drawBlocks(canvas, c, r, primary, secondary);
        break;
      case AppIllustrationKind.wizardScores:
        _drawChartBars(canvas, c, r, primary);
        break;
      case AppIllustrationKind.wizardInterests:
        _drawHearts(canvas, c, r, primary, secondary);
        break;
      case AppIllustrationKind.wizardStrengths:
        _drawStar(canvas, c, r * 0.55, secondary);
        break;
      case AppIllustrationKind.wizardRegion:
        _drawMapPin(canvas, c, r, primary);
        break;
      case AppIllustrationKind.wizardResults:
        _drawTrophy(canvas, c, r, primary, secondary);
        break;
      case AppIllustrationKind.charts:
        _drawChartLine(canvas, c, r, primary, secondary);
        break;
      case AppIllustrationKind.chat:
        _drawChatBubble(canvas, c, r, primary);
        break;
      case AppIllustrationKind.forum:
        _drawPeople(canvas, c, r, primary, secondary);
        break;
      case AppIllustrationKind.emptyState:
        _drawSearch(canvas, c, r, AppColors.gray);
        break;
    }
  }

  void _drawGraduation(Canvas canvas, Offset c, double r, Color p, Color s) {
    final cap = Path()
      ..moveTo(c.dx - r, c.dy - r * 0.1)
      ..lineTo(c.dx, c.dy - r * 0.55)
      ..lineTo(c.dx + r, c.dy - r * 0.1)
      ..close();
    canvas.drawPath(cap, Paint()..color = p);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.15), width: r * 1.1, height: r * 0.75),
      Paint()..color = s.withValues(alpha: 0.85),
    );
    final tassel = Paint()..color = AppColors.warning;
    canvas.drawCircle(Offset(c.dx + r * 0.85, c.dy - r * 0.05), r * 0.08, tassel);
  }

  void _drawBook(Canvas canvas, Offset o, double w) {
    final paint = Paint()..color = AppColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: w * 1.4, height: w),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(o.dx, o.dy - w * 0.4),
      Offset(o.dx, o.dy + w * 0.4),
      Paint()
        ..color = primary.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
  }

  void _drawBlocks(Canvas canvas, Offset c, double r, Color p, Color s) {
    final rects = [
      (Offset(c.dx - r * 0.5, c.dy), p),
      (Offset(c.dx, c.dy - r * 0.2), s),
      (Offset(c.dx + r * 0.45, c.dy + r * 0.1), p.withValues(alpha: 0.7)),
    ];
    for (final (o, col) in rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: r * 0.55, height: r * 0.7),
          const Radius.circular(10),
        ),
        Paint()..color = col,
      );
    }
  }

  void _drawChartBars(Canvas canvas, Offset c, double r, Color p) {
    final bars = [0.5, 0.75, 0.95, 0.65];
    final bw = r * 0.22;
    for (var i = 0; i < bars.length; i++) {
      final h = r * bars[i];
      final left = c.dx - r * 0.65 + i * (bw + 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, c.dy + r * 0.35 - h, bw, h),
          const Radius.circular(4),
        ),
        Paint()..color = Color.lerp(p, AppColors.secondary, i / 3)!,
      );
    }
  }

  void _drawHearts(Canvas canvas, Offset c, double r, Color p, Color s) {
    void heart(Offset o, Color col, double scale) {
      final path = Path();
      final sz = r * 0.22 * scale;
      path.moveTo(o.dx, o.dy + sz * 0.3);
      path.cubicTo(o.dx - sz, o.dy - sz, o.dx - sz * 1.4, o.dy + sz * 0.2, o.dx, o.dy + sz);
      path.cubicTo(o.dx + sz * 1.4, o.dy + sz * 0.2, o.dx + sz, o.dy - sz, o.dx, o.dy + sz * 0.3);
      canvas.drawPath(path, Paint()..color = col);
    }

    heart(Offset(c.dx - r * 0.35, c.dy), p, 1.1);
    heart(Offset(c.dx + r * 0.3, c.dy - r * 0.15), s, 1.0);
    heart(Offset(c.dx, c.dy + r * 0.25), p.withValues(alpha: 0.6), 0.85);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color col) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 4 * math.pi / 5;
      final pt = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = col);
  }

  void _drawMapPin(Canvas canvas, Offset c, double r, Color p) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.55)
      ..quadraticBezierTo(c.dx - r * 0.05, c.dy, c.dx, c.dy - r * 0.45)
      ..quadraticBezierTo(c.dx + r * 0.05, c.dy, c.dx, c.dy + r * 0.55);
    canvas.drawPath(path, Paint()..color = p);
    canvas.drawCircle(Offset(c.dx, c.dy - r * 0.2), r * 0.22, Paint()..color = AppColors.white);
  }

  void _drawTrophy(Canvas canvas, Offset c, double r, Color p, Color s) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.45, c.dy - r * 0.15)
        ..lineTo(c.dx - r * 0.35, c.dy - r * 0.55)
        ..lineTo(c.dx + r * 0.35, c.dy - r * 0.55)
        ..lineTo(c.dx + r * 0.45, c.dy - r * 0.15)
        ..close(),
      Paint()..color = p,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.35), width: r * 0.5, height: r * 0.25),
      Paint()..color = s,
    );
    _drawStar(canvas, Offset(c.dx, c.dy - r * 0.35), r * 0.2, AppColors.warning);
  }

  void _drawChartLine(Canvas canvas, Offset c, double r, Color p, Color s) {
    final path = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.2)
      ..lineTo(c.dx - r * 0.35, c.dy - r * 0.1)
      ..lineTo(c.dx + r * 0.1, c.dy + r * 0.05)
      ..lineTo(c.dx + r, c.dy - r * 0.35);
    canvas.drawPath(
      path,
      Paint()
        ..color = p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(c.dx + r, c.dy - r * 0.35), 6, Paint()..color = s);
  }

  void _drawChatBubble(Canvas canvas, Offset c, double r, Color p) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy - r * 0.05), width: r * 1.5, height: r),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, Paint()..color = p);
    final tail = Path()
      ..moveTo(c.dx - r * 0.15, c.dy + r * 0.4)
      ..lineTo(c.dx - r * 0.35, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.05, c.dy + r * 0.4);
    canvas.drawPath(tail, Paint()..color = p);
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(c.dx + i * r * 0.28, c.dy - r * 0.05),
        r * 0.07,
        Paint()..color = AppColors.white.withValues(alpha: 0.9),
      );
    }
  }

  void _drawPeople(Canvas canvas, Offset c, double r, Color p, Color s) {
    for (var i = -1; i <= 1; i++) {
      final col = i == 0 ? p : (i < 0 ? s : p.withValues(alpha: 0.65));
      final ox = c.dx + i * r * 0.42;
      canvas.drawCircle(Offset(ox, c.dy - r * 0.25), r * 0.2, Paint()..color = col);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(ox, c.dy + r * 0.2), width: r * 0.5, height: r * 0.55),
          const Radius.circular(12),
        ),
        Paint()..color = col,
      );
    }
  }

  void _drawSearch(Canvas canvas, Offset c, double r, Color col) {
    canvas.drawCircle(c, r * 0.45, Paint()
      ..color = col.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);
    canvas.drawLine(
      Offset(c.dx + r * 0.28, c.dy + r * 0.28),
      Offset(c.dx + r * 0.55, c.dy + r * 0.55),
      Paint()
        ..color = col
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.kind != kind || old.primary != primary;
}

