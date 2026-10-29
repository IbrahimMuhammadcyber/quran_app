import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  AppColors(this.isDark);

  Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F0);
  Color get surface => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get surfaceAlt => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1EBDD);
  Color get card => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEFE8D8);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF4A4A4A);
  Color get textMuted => isDark ? Colors.white54 : const Color(0xFF7A7A7A);
  Color get textFaint => isDark ? Colors.white38 : const Color(0xFFA0A0A0);
  Color get divider => isDark ? Colors.white12 : const Color(0xFFE0D8C0);
  Color get accent => const Color(0xFFD4AF37);
}
