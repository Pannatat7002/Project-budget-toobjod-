import 'package:flutter/material.dart';

class AppColors {
  // 4 Core Master Colors for ToobJod App:
  // 1. 🟧 Vibrant Shiba Orange (#FF7A00 / #EA580C / #FB923C)
  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryLight = Color(0xFFFB923C);
  static const Color primaryOrange = Color(0xFFFF7A00);
  static const Color mascotOrange = Color(0xFFFF7A00);
  static const Color mascotOrangeLight = Color(0xFFFB923C);

  // 2. 🌌 Midnight Deep Navy (#0B132B / #131E3A / #18264A / #22355E)
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF131E3A);
  static const Color darkCard = Color(0xFF18264A);
  static const Color darkCardHover = Color(0xFF1F325E);
  static const Color darkBorder = Color(0xFF22355E);
  static const Color darkBorderSubtle = Color(0xFF1A2A4C);

  // 3. 🔷 Royal Action Blue (#2563EB / #3B82F6 / #1D4ED8)
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF1D4ED8);
  static const Color info = Color(0xFF3B82F6);

  // 4. 🤍 White & Crisp Slate (#FFFFFF / #F8FAFC / #94A3B8 / #64748B)
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Financial Semantics (Integrated into 4-Color system)
  static const Color income = Color(0xFF2563EB); // Royal Blue for positive / income
  static const Color incomeLight = Color(0xFFDBEAFE);
  static const Color expense = Color(0xFFFF7A00); // Vibrant Orange for expense
  static const Color expenseLight = Color(0xFFFFEDD5);
  static const Color warning = Color(0xFFFF7A00);
  static const Color warningLight = Color(0xFFFFEDD5);

  // Light Theme Palette (Clean White / Soft Off-white using 4-Color Harmony)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0B132B); // Midnight Navy for dark text
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Gradients (4-Color Harmony)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeBadgeGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowBadgeGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueActionGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF7A00), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
