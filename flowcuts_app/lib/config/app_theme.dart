import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFD4AF37);      // Gold
  static const Color primaryDark = Color(0xFFB8860B);  // Dark Gold
  static const Color primaryLight = Color(0xFFF5D76E); // Light Gold
  static const Color accent = Color(0xFFFF6B35);       // Coral accent
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Backgrounds
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color card = Color(0xFF1A1A26);
  static const Color cardHover = Color(0xFF222235);
  static const Color border = Color(0xFF2A2A3E);

  // Text
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9090A8);
  static const Color textMuted = Color(0xFF5A5A72);

  // Status colors
  static const Color statusScheduled = Color(0xFF3498DB);
  static const Color statusConfirmed = Color(0xFF27AE60);
  static const Color statusCancelled = Color(0xFFE74C3C);
  static const Color statusCompleted = Color(0xFF9B59B6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme Data ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Color(0xFF0A0A0F),
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: const TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
          labelLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardHover,
        contentTextStyle: GoogleFonts.outfit(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'scheduled': return statusScheduled;
      case 'confirmed': return statusConfirmed;
      case 'cancelled': return statusCancelled;
      case 'completed': return statusCompleted;
      default: return textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'scheduled': return 'Pendiente';
      case 'confirmed': return 'Confirmada';
      case 'cancelled': return 'Cancelada';
      case 'completed': return 'Completada';
      default: return status;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'scheduled': return Icons.schedule_rounded;
      case 'confirmed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'completed': return Icons.done_all_rounded;
      default: return Icons.help_outline_rounded;
    }
  }
}
