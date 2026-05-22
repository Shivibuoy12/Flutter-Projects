import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'trader_colors.dart';

ThemeData buildTraderTheme({bool dark = true}) {
  final baseText = GoogleFonts.dmSansTextTheme(Typography.material2021(platform: TargetPlatform.android).black);
  final textTheme = baseText.apply(
    bodyColor: TraderColors.textPrimary,
    displayColor: TraderColors.textPrimary,
  );
  final scheme = ColorScheme.dark(
    surface: TraderColors.surface,
    primary: TraderColors.accent,
    secondary: TraderColors.textSecondary,
    onSurface: TraderColors.textPrimary,
    outline: TraderColors.border,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: TraderColors.scaffold,
    dividerColor: TraderColors.border,
    dividerTheme: const DividerThemeData(color: TraderColors.border, thickness: 0.6),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: TraderColors.surface,
      foregroundColor: TraderColors.textPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: TraderColors.textPrimary),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: TraderColors.surface,
      indicatorColor: TraderColors.accent.withValues(alpha: 0.22),
      selectedIconTheme: const IconThemeData(color: TraderColors.accent),
      unselectedIconTheme: const IconThemeData(color: TraderColors.textSecondary),
      selectedLabelTextStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: TraderColors.accent),
      unselectedLabelTextStyle: GoogleFonts.dmSans(fontSize: 11, color: TraderColors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TraderColors.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: const TextStyle(color: TraderColors.textSecondary, fontSize: 13),
    ),
    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(color: TraderColors.surface, borderRadius: BorderRadius.circular(8)),
      headingTextStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: TraderColors.textSecondary,
      ),
      dataTextStyle: GoogleFonts.dmSans(fontSize: 13, color: TraderColors.textPrimary),
    ),
  );
}
