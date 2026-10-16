import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Smooth line chart with a gradient fill that draws itself in
/// (the "Status" box on the profile page).
class SimpleLineChart extends StatelessWidget {
  final List<int> values;
  const SimpleLineChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) =>
            CustomPaint(painter: _LinePainter(values, t, palette)),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<int> values;
  final double progress;
  final AppPalette palette;
  _LinePainter(this.values, this.progress, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = palette.muted.withAlpha(45)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;

    final maxV = max(values.reduce(max), 1);
    final stepX = size.width / (values.length - 1);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(
          i * stepX,
          size.height - (values[i] / maxV) * (size.height - 16) - 8,
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      line.cubicTo(a.dx + stepX / 2, a.dy, b.dx - stepX / 2, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.blue.withAlpha(110), palette.blue.withAlpha(0)],
        ).createShader(rect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..shader = LinearGradient(
          colors: [palette.cyan, palette.blueLight],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = palette.blue;
    for (final p in pts) {
      if (p.dx <= size.width * progress) canvas.drawCircle(p, 3, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.palette != palette;
}

/// Bar chart whose bars grow upward one after another
/// (the "Progress" box on the profile page).
class SimpleBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  const SimpleBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final maxV = max(values.isEmpty ? 1 : values.reduce(max), 1);
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${values[i]}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 3),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: values[i] / maxV),
                      duration: Duration(milliseconds: 600 + i * 140),
                      curve: Curves.easeOutBack,
                      builder: (_, t, __) => Container(
                        height: max(6.0, 120 * t),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: values[i] == maxV
                                ? [palette.cyan, palette.blue]
                                : [palette.blueLight, palette.blue],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
