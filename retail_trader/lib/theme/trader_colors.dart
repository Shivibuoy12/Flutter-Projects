import 'package:flutter/material.dart';

/// Webull-ish dark workstation palette (inspired styling; not affiliated).
abstract final class TraderColors {
  static const Color scaffold = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF121826);
  static const Color surfaceElevated = Color(0xFF161D2C);
  static const Color border = Color(0xFF273244);
  static const Color textPrimary = Color(0xFFE8EDF6);
  static const Color textSecondary = Color(0xFF8B98AD);
  static const Color accent = Color(0xFF2979FF);
  static const Color up = Color(0xFF00C853);
  static const Color down = Color(0xFFFF5252);
  static const Color warn = Color(0xFFFFB74D);

  static Color sideColor(bool buy) => buy ? up : down;
}
