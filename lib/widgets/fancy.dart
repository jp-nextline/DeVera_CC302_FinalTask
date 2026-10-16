import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/image_service.dart';
import '../theme.dart';

/// Picks black/white text that is readable on [c].
Color onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark
    ? Colors.white
    : Colors.black87;

// ===================================================== background / scaffold
class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow(this.color, this.size);

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    ),
  );
}

/// Deep navy gradient with two soft glows, like the reference design.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.bgTop, palette.bgBottom],
              ),
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -90,
          child: _Glow(palette.blue.withAlpha(isDark ? 90 : 28), 340),
        ),
        Positioned(
          bottom: -140,
          left: -120,
          child: _Glow(palette.purple.withAlpha(isDark ? 60 : 22), 360),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Scaffold with the navy background and a transparent app bar. Pages inside
/// the main shell pass useGradient: false (the shell paints the background).
class GradientScaffold extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool useGradient;

  const GradientScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBar = title != null || actions != null || leading != null;
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: hasBar
          ? AppBar(
              title: title,
              leading: leading,
              actions: actions,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
    return useGradient ? AppBackground(child: scaffold) : scaffold;
  }
}

// ============================================================== motion
/// Press-and-release "bounce": shrinks while pressed, springs back on release.
/// Uses a Listener so it never interferes with the button's own tap handling.
class Bounce extends StatefulWidget {
  final Widget child;
  final double scale;
  final bool enabled;
  const Bounce({
    super.key,
    required this.child,
    this.scale = 0.93,
    this.enabled = true,
  });

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> {
  bool _down = false;

  void _release() {
    // keep the squish visible for a moment, even on very quick taps
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _down = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides its child up when first shown (staggered by [index]).
class FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;
  const FadeSlideIn({super.key, this.index = 0, required this.child});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index.clamp(0, 8)) * 70;
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Number that counts up to [value] whenever it changes.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String suffix;
  const CountUp(this.value, {super.key, this.style, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$v$suffix', style: style),
    );
  }
}

// ================================================================= cards
/// Navy rounded card with soft shadows (a coloured glow when it has a
/// gradient). Animates in when [entranceIndex] is set and bounces when tapped.
class DepthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final int? entranceIndex;

  const DepthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.onTap,
    this.onLongPress,
    this.radius = 24,
    this.margin,
    this.entranceIndex,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = color ?? palette.card;
    final colors =
        gradient ?? [base, Color.alphaBlend(Colors.black.withAlpha(35), base)];
    final r = BorderRadius.circular(radius);
    final tappable = onTap != null || onLongPress != null;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withAlpha(
            gradient == null ? 16 : 30,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient == null
                ? Colors.black.withAlpha(isDark ? 90 : 18)
                : colors.first.withAlpha(isDark ? 110 : 52),
            blurRadius: gradient == null ? 20 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (tappable) card = Bounce(scale: 0.96, child: card);
    if (entranceIndex != null) {
      card = FadeSlideIn(index: entranceIndex!, child: card);
    }
    return card;
  }
}

// =============================================================== buttons
/// Pill button with gradient + glow and a bounce animation.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.outlined = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final palette = context.appPalette;
    final r = BorderRadius.circular(26);
    return Bounce(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: outlined
                ? null
                : LinearGradient(
                    colors: [palette.blueLight, palette.blue, palette.purple],
                  ),
            border: outlined
                ? Border.all(color: Colors.white.withAlpha(80))
                : null,
            boxShadow: outlined || !enabled
                ? null
                : [
                    BoxShadow(
                      color: palette.blue.withAlpha(130),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: r,
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-square coloured icon, like the category icons in the reference.
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(48),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Circular avatar with a gradient ring and the user's initial.
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const UserAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [palette.cyan, palette.blue, palette.purple],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.blue.withAlpha(120),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: palette.card,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: onColor(palette.card),
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.9,
          ),
        ),
      ),
    );
  }
}

// ================================================================ inputs
InputDecoration appInputDecoration(
  BuildContext context,
  String label, {
  Widget? prefix,
  Widget? suffix,
}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
  final cs = Theme.of(context).colorScheme;
  final palette = context.appPalette;
  final borderColor =
      (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
          .withAlpha(28);
  return InputDecoration(
    labelText: label,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: palette.cardLight.withAlpha(210),
    enabledBorder: b(borderColor),
    focusedBorder: b(palette.blueLight, 1.6),
    errorBorder: b(cs.error),
    focusedErrorBorder: b(cs.error, 1.6),
    border: b(borderColor),
  );
}

// ================================================================ images
/// Shows a stored image by name (renders nothing if it is missing).
class AppImage extends StatelessWidget {
  final String? name;
  final BoxFit fit;
  const AppImage(this.name, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (name == null) return const SizedBox.shrink();
    if (kIsWeb) {
      final bytes = ImageService.webBytes(name!);
      if (bytes == null) return const SizedBox.shrink();
      return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    }
    return Image.file(
      ImageService.file(name!),
      fit: fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Circular gradient logo used on the login, home and summary screens.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _BrandLogoPainter()),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  static const _ink = Color(0xFF050505);
  static const _paper = Colors.white;

  const _BrandLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 768, size.height / 768);

    canvas.drawCircle(const Offset(384, 384), 352, Paint()..color = _paper);
    _drawCard(canvas, const Offset(260, 425), -0.35);
    _drawCard(canvas, const Offset(508, 425), 0.35);
    _drawBrain(canvas);
    _drawLetter(canvas, 'B', const Offset(264, 410), 360, -0.35);
    _drawLetter(canvas, 'H', const Offset(506, 410), 350, 0.35);

    canvas.drawCircle(
      const Offset(384, 384),
      352,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.restore();
  }

  void _drawCard(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 300, height: 350),
      const Radius.circular(28),
    );
    canvas.drawRRect(card, Paint()..color = _paper);
    canvas.drawRRect(
      card,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  void _drawBrain(Canvas canvas) {
    final half = Path()
      ..moveTo(384, 122)
      ..cubicTo(356, 105, 325, 119, 307, 151)
      ..cubicTo(278, 137, 253, 147, 241, 170)
      ..cubicTo(229, 192, 235, 214, 250, 231)
      ..cubicTo(224, 239, 210, 259, 214, 283)
      ..cubicTo(239, 278, 258, 266, 279, 263)
      ..cubicTo(302, 260, 314, 278, 337, 280)
      ..cubicTo(359, 282, 376, 267, 384, 249)
      ..close();

    final brainPaint = Paint()..color = _ink;
    canvas.drawPath(half, brainPaint);
    canvas.save();
    canvas.translate(768, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(half, brainPaint);
    canvas.restore();

    final fold = Path()
      ..moveTo(293, 182)
      ..cubicTo(276, 202, 290, 224, 315, 235)
      ..cubicTo(340, 247, 365, 237, 383, 219);
    final foldPaint = Paint()
      ..color = _paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fold, foldPaint);
    canvas.save();
    canvas.translate(768, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(fold, foldPaint);
    canvas.restore();

    canvas.drawLine(
      const Offset(384, 132),
      const Offset(384, 250),
      Paint()
        ..color = _paper
        ..strokeWidth = 7,
    );
  }

  void _drawLetter(
    Canvas canvas,
    String letter,
    Offset center,
    double fontSize,
    double angle,
  ) {
    final outline = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Arial',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 26
            ..strokeJoin = StrokeJoin.round,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fill = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Arial',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: _paper,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final offset = Offset(-outline.width / 2, -outline.height / 2);
    outline.paint(canvas, offset);
    fill.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandLogoPainter oldDelegate) => false;
}
