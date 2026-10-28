import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color accent = Color(0xFF0EA5E9);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF2563EB);
  static const Color statusCheckedIn = Color(0xFF16A34A);
  static const Color statusCheckedOut = Color(0xFF64748B);
  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusCancelled = Color(0xFF94A3B8);

  static const Color darkBackground = Color(0xFF08111F);
  static const Color darkSurface = Color(0xFF111C2E);
  static const Color darkBorder = Color(0xFF1E2C42);

  static const LinearGradient heroGradient = LinearGradient(
    colors: <Color>[Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> avatarPalette = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
  ];
}
