import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color cardLight;
  final Color blue;
  final Color blueLight;
  final Color cyan;
  final Color purple;
  final Color orange;
  final Color green;
  final Color pink;
  final Color muted;

  const AppPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.cardLight,
    required this.blue,
    required this.blueLight,
    required this.cyan,
    required this.purple,
    required this.orange,
    required this.green,
    required this.pink,
    required this.muted,
  });

  List<Color> get colors => [blue, cyan, purple, orange, green, pink];

  @override
  AppPalette copyWith({
    Color? bgTop,
    Color? bgBottom,
    Color? card,
    Color? cardLight,
    Color? blue,
    Color? blueLight,
    Color? cyan,
    Color? purple,
    Color? orange,
    Color? green,
    Color? pink,
    Color? muted,
  }) => AppPalette(
    bgTop: bgTop ?? this.bgTop,
    bgBottom: bgBottom ?? this.bgBottom,
    card: card ?? this.card,
    cardLight: cardLight ?? this.cardLight,
    blue: blue ?? this.blue,
    blueLight: blueLight ?? this.blueLight,
    cyan: cyan ?? this.cyan,
    purple: purple ?? this.purple,
    orange: orange ?? this.orange,
    green: green ?? this.green,
    pink: pink ?? this.pink,
    muted: muted ?? this.muted,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardLight: Color.lerp(cardLight, other.cardLight, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueLight: Color.lerp(blueLight, other.blueLight, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      green: Color.lerp(green, other.green, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static ThemeData build(AppPalette palette, Brightness brightness) {
    final cs =
        ColorScheme.fromSeed(
          seedColor: palette.blue,
          brightness: brightness,
        ).copyWith(
          primary: palette.blue,
          onPrimary: Colors.white,
          primaryContainer: palette.cardLight,
          onPrimaryContainer: brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF172033),
          secondary: palette.cyan,
          onSecondary: const Color(0xFF00222B),
          tertiary: palette.purple,
          onTertiary: Colors.white,
          surface: palette.bgTop,
          onSurface: brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF172033),
          onSurfaceVariant: palette.muted,
          surfaceContainerLow: palette.card,
          surfaceContainer: palette.card,
          surfaceContainerHigh: palette.card,
          surfaceContainerHighest: palette.cardLight,
          outlineVariant: palette.muted.withAlpha(90),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      extensions: [palette],
      scaffoldBackgroundColor: palette.bgBottom,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF34457F)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.cardLight,
        contentTextStyle: TextStyle(color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
