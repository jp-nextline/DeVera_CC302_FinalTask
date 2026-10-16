import 'package:flutter/material.dart';

import 'theme.dart';

class AppThemeOption {
  final String id;
  final String name;
  final Brightness brightness;
  final AppPalette palette;

  const AppThemeOption(this.id, this.name, this.brightness, this.palette);
}

class AppThemes {
  static const List<AppThemeOption> all = [
    AppThemeOption(
      'light',
      'Light',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFF8FAFD),
        bgBottom: Color(0xFFF1F4F8),
        card: Colors.white,
        cardLight: Color(0xFFE9EEF5),
        blue: Color(0xFF315FEA),
        blueLight: Color(0xFF5277F0),
        cyan: Color(0xFF008DA6),
        purple: Color(0xFF7656D6),
        orange: Color(0xFFCE7600),
        green: Color(0xFF178663),
        pink: Color(0xFFC74670),
        muted: Color(0xFF657184),
      ),
    ),
    AppThemeOption(
      'midnight',
      'Midnight (Classic)',
      Brightness.dark,
      AppPalette(
        bgTop: Color(0xFF16234F),
        bgBottom: Color(0xFF0A1130),
        card: Color(0xFF1B2858),
        cardLight: Color(0xFF263670),
        blue: Color(0xFF3E63F5),
        blueLight: Color(0xFF5B86FF),
        cyan: Color(0xFF31C9E8),
        purple: Color(0xFF7C5CFF),
        orange: Color(0xFFFFA630),
        green: Color(0xFF2DD4A0),
        pink: Color(0xFFFF6B9D),
        muted: Color(0xFF9AA8D4),
      ),
    ),
    AppThemeOption(
      'violet',
      'Violet Dream',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFF9F7FF),
        bgBottom: Color(0xFFF3F0FC),
        card: Colors.white,
        cardLight: Color(0xFFECE7F8),
        blue: Color(0xFF6249D8),
        blueLight: Color(0xFF806AE8),
        cyan: Color(0xFF008FA2),
        purple: Color(0xFF8A56C8),
        orange: Color(0xFFC87814),
        green: Color(0xFF30805D),
        pink: Color(0xFFC34778),
        muted: Color(0xFF6F6880),
      ),
    ),
    AppThemeOption(
      'ocean',
      'Ocean Breeze',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFF3FAFC),
        bgBottom: Color(0xFFEAF5F8),
        card: Colors.white,
        cardLight: Color(0xFFDDEEF2),
        blue: Color(0xFF087E9C),
        blueLight: Color(0xFF24A5BB),
        cyan: Color(0xFF00A9A0),
        purple: Color(0xFF6F69B5),
        orange: Color(0xFFD27A33),
        green: Color(0xFF20836C),
        pink: Color(0xFFC95878),
        muted: Color(0xFF5C747C),
      ),
    ),
    AppThemeOption(
      'forest',
      'Forest',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFF5FAF6),
        bgBottom: Color(0xFFEDF5EF),
        card: Colors.white,
        cardLight: Color(0xFFE1EEE4),
        blue: Color(0xFF3979A8),
        blueLight: Color(0xFF5595B7),
        cyan: Color(0xFF168E91),
        purple: Color(0xFF7961AE),
        orange: Color(0xFFC37A28),
        green: Color(0xFF377D4E),
        pink: Color(0xFFC35B71),
        muted: Color(0xFF66766B),
      ),
    ),
    AppThemeOption(
      'sunset',
      'Sunset',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFFFF9F5),
        bgBottom: Color(0xFFFCF1E9),
        card: Colors.white,
        cardLight: Color(0xFFF5E5D9),
        blue: Color(0xFF3973B5),
        blueLight: Color(0xFF5A91C8),
        cyan: Color(0xFF078E9B),
        purple: Color(0xFF8057A8),
        orange: Color(0xFFDA653C),
        green: Color(0xFF41805B),
        pink: Color(0xFFD64D70),
        muted: Color(0xFF806D63),
      ),
    ),
    AppThemeOption(
      'blossom',
      'Blossom',
      Brightness.light,
      AppPalette(
        bgTop: Color(0xFFFFF7FA),
        bgBottom: Color(0xFFF8EEF3),
        card: Colors.white,
        cardLight: Color(0xFFF0E1E9),
        blue: Color(0xFF426FB4),
        blueLight: Color(0xFF6487CA),
        cyan: Color(0xFF008D9A),
        purple: Color(0xFF7957B4),
        orange: Color(0xFFC7782C),
        green: Color(0xFF41816A),
        pink: Color(0xFFD44978),
        muted: Color(0xFF7C6670),
      ),
    ),
    AppThemeOption(
      'neon',
      'Neon Nights',
      Brightness.dark,
      AppPalette(
        bgTop: Color(0xFF1B163A),
        bgBottom: Color(0xFF100D25),
        card: Color(0xFF28204B),
        cardLight: Color(0xFF392C62),
        blue: Color(0xFF8270FF),
        blueLight: Color(0xFFA196FF),
        cyan: Color(0xFF35D6D0),
        purple: Color(0xFFC252E8),
        orange: Color(0xFFFFA746),
        green: Color(0xFF4AD6A2),
        pink: Color(0xFFFF6FA5),
        muted: Color(0xFFB6AED6),
      ),
    ),
    AppThemeOption(
      'mocha',
      'Mocha',
      Brightness.dark,
      AppPalette(
        bgTop: Color(0xFF30251F),
        bgBottom: Color(0xFF211915),
        card: Color(0xFF40322A),
        cardLight: Color(0xFF554338),
        blue: Color(0xFF6FA8C9),
        blueLight: Color(0xFF91C4D9),
        cyan: Color(0xFF54C3B5),
        purple: Color(0xFFB28BCC),
        orange: Color(0xFFE79A53),
        green: Color(0xFF7ABF8E),
        pink: Color(0xFFE77E96),
        muted: Color(0xFFC7B6A8),
      ),
    ),
  ];

  static AppThemeOption byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
