import 'package:flutter/material.dart';

/// Paleta de colores centralizada. Cámbiala aquí y se actualiza toda la app.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF2E5BFF);
  static const primaryLight = Color(0xFF5B7CFF);
  static const secondary = Color(0xFF7C6FEE);
  static const background = Color(0xFFF4F6FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1D29);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const border = Color(0xFFE5E9F2);
  static const fieldFill = Color(0xFFF7F8FC);
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Helper para adaptar espaciados/tamaños según el ancho real de pantalla.
/// Esto es lo que evita que la app se vea "cortada" o gigante en celulares
/// con pantallas muy chicas o muy grandes.
class Responsive {
  final BuildContext context;
  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  bool get isSmallHeight => height < 700;
  bool get isNarrow => width < 360;

  double get horizontalPadding => isNarrow ? 16 : 24;
  double get cardPadding => isSmallHeight ? 20 : 28;
}
