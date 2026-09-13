import 'package:flutter/material.dart';

/// Centralized design system color palette crafted to harmonize with the
/// FirmLedger F-Ribbon blue logo while maximizing visual comfort and readability.
class AppColors {
  // Brand Blues & Cyans derived from the F-Ribbon logo
  static const Color primaryBlue = Color(0xFF0D6EFD);       // Vibrant Royal Azure Blue
  static const Color primaryDark = Color(0xFF0A2540);       // Deep Midnight Navy (Eye-comfortable header/base)
  static const Color primaryNavy = Color(0xFF0F172A);       // Ultra-deep Navy slate
  static const Color electricCyan = Color(0xFF38BDF8);      // Electric Cyan from the ribbon fold
  static const Color skyAccent = Color(0xFF0EA5E9);         // Sky Blue highlight
  static const Color softBlueTint = Color(0xFFEFF6FF);      // Soft comfortable background tint
  static const Color cardBorderLight = Color(0xFFDBEAFE);   // Gentle subtle blue border

  // Neutral Backgrounds for visual comfort & reduced eye strain
  static const Color scaffoldLight = Color(0xFFF8FAFC);     // Gentle Slate-50 background (avoids glare)
  static const Color surfaceLight = Colors.white;
  static const Color scaffoldDark = Color(0xFF0B1329);      // Deep Midnight Obsidian
  static const Color cardSurfaceDark = Color(0xFF152238);   // Elevated Slate Navy
  static const Color cardBorderDark = Color(0xFF1E293B);    // Subtle dark border

  // Semantic Accounting Colors (Preserved for crystal-clear financial distinction)
  static const Color incomeGreen = Color(0xFF10B981);       // Emerald green for income & gains
  static const Color expenseRed = Color(0xFFEF4444);        // Coral red for expense & debts due
  static const Color receivables = Color(0xFF0284C7);       // Sky blue for money to receive
  static const Color payables = Color(0xFFD97706);          // Amber for money owed
  static const Color gold = Color(0xFFD97706);              // Bullion gold
  static const Color silver = Color(0xFF64748B);            // Bullion silver
}
