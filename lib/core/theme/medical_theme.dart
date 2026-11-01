import 'package:flutter/material.dart';

class MedicalColors {
  // Base workstation dark slate
  static const Color background = Color(0xFF090E17);
  static const Color surface = Color(0xFF101928);
  static const Color surfaceElevated = Color(0xFF16233B);
  static const Color border = Color(0xFF1F3254);
  static const Color borderLight = Color(0xFF2C446F);

  // Medical Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color cyanDim = Color(0xFF0096B0);
  static const Color primaryTeal = Color(0xFF00B4D8);
  static const Color accentBlue = Color(0xFF2D7FF9);

  // Clinical Risk Codes
  static const Color riskHigh = Color(0xFFFF2A55);
  static const Color riskModerateHigh = Color(0xFFFF8C00);
  static const Color riskModerateLow = Color(0xFFFFC107);
  static const Color riskLow = Color(0xFF00C896);
  static const Color riskNormal = Color(0xFF00E676);

  // Status and Utilities
  static const Color textPrimary = Color(0xFFF0F4FA);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color thresholdTick = Color(0xFFFFFFFF);

  // Risk Color Mapping
  static Color forRiskCode(String? riskCode, bool isPositive) {
    if (isPositive) {
      if (riskCode == 'HIGH') return riskHigh;
      if (riskCode == 'MODERATE_HIGH') return riskModerateHigh;
      return riskHigh;
    }
    if (riskCode == 'MODERATE_LOW') return riskModerateLow;
    if (riskCode == 'LOW') return riskLow;
    return riskNormal;
  }
}

class MedicalTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MedicalColors.background,
      colorScheme: const ColorScheme.dark(
        primary: MedicalColors.primaryCyan,
        onPrimary: Color(0xFF002029),
        surface: MedicalColors.surface,
        onSurface: MedicalColors.textPrimary,
        error: MedicalColors.riskHigh,
      ),
      cardTheme: CardThemeData(
        color: MedicalColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: MedicalColors.border, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: MedicalColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: MedicalColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MedicalColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: MedicalColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: MedicalColors.primaryCyan,
        inactiveTrackColor: MedicalColors.border,
        thumbColor: MedicalColors.primaryCyan,
        overlayColor: MedicalColors.primaryCyan.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: MedicalColors.border,
        thickness: 1,
      ),
    );
  }
}
