import 'package:flutter/material.dart';

/// One place for every colour, size and radius. Change here, whole app follows.
class HL {
  // Brand
  static const wine = Color(0xFF7B2A3B);
  static const blush = Color(0xFFFFDDE0);
  static const blushSoft = Color(0xFFFFF0F1);
  static const cream = Color(0xFFFAF7F2);
  static const ink = Color(0xFF241A1C);
  static const muted = Color(0xFF7A6E70);
  static const line = Color(0xFFF1D6DA);

  // Spacing
  static const double pad = 16;
  static const double gap = 12;
  static const double radius = 20;

  // Type scale (use ONLY these four)
  static const title = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w800, color: wine, height: 1.1);
  static const section = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: ink);
  static const body = TextStyle(fontSize: 15, color: ink, height: 1.35);
  static const caption = TextStyle(fontSize: 13, color: muted);

  // Card look
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: wine.withValues(alpha: 0.6),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
}
