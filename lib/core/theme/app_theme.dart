import 'package:flutter/material.dart';

import '../../models/severity.dart';

/// Espaciados reutilizables (múltiplos de 4).
class NetSpacing {
  NetSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Radios de esquina reutilizables.
class NetRadius {
  NetRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// Paleta de NetLab: azul marino oscuro, acento cian y semáforo de estados.
class NetColors {
  NetColors._();

  static const background = Color(0xFF070D1F);
  static const surface = Color(0xFF0F1A36);
  static const surfaceHigh = Color(0xFF16244A);
  static const border = Color(0xFF263769);
  static const primary = Color(0xFF22D3EE); // cian: botones y selección
  static const electric = Color(0xFF3B82F6); // azul eléctrico: secundario
  static const accent = primary;
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFE6ECFF);
  static const textMuted = Color(0xFF9AAAD0); // contraste > 6:1 sobre surface
  static const selectedTint = Color(0x3322D3EE);
}

const TextStyle monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas', 'Courier'],
  fontSize: 12.5,
  height: 1.4,
  color: NetColors.textPrimary,
);

/// Color de cada método HTTP (o tipo de prueba) para insignias y selectores.
Color methodColor(String method) => switch (method.toUpperCase()) {
      'GET' => const Color(0xFF22D3EE),
      'POST' => const Color(0xFF60A5FA),
      'PUT' => const Color(0xFFA78BFA),
      'PATCH' => const Color(0xFFF472B6),
      'DELETE' => const Color(0xFFFB7185),
      'DIAGNÓSTICO' => const Color(0xFF2DD4BF),
      _ => NetColors.textMuted, // DIO y otros
    };

/// Estilos de texto secundarios, derivados del tema para respetar el escalado.
class NetText {
  NetText._();
  static TextStyle muted(BuildContext c, {double? size}) =>
      Theme.of(c).textTheme.bodySmall!.copyWith(
            color: NetColors.textMuted,
            fontSize: size,
          );
}

extension SeverityColor on Severity {
  Color get color => switch (this) {
        Severity.ok => NetColors.success,
        Severity.warn => NetColors.warning,
        Severity.error => NetColors.error,
        Severity.info => NetColors.accent,
        Severity.neutral => NetColors.textMuted,
      };
}

ThemeData buildNetLabTheme() {
  const scheme = ColorScheme.dark(
    primary: NetColors.primary,
    onPrimary: NetColors.background, // texto oscuro sobre cian
    secondary: NetColors.electric,
    secondaryContainer: NetColors.surfaceHigh,
    onSecondaryContainer: NetColors.textPrimary,
    surface: NetColors.surface,
    onSurface: NetColors.textPrimary,
    onSurfaceVariant: NetColors.textMuted,
    error: NetColors.error,
    outline: NetColors.border,
    outlineVariant: NetColors.border,
  );

  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  var text = base.textTheme.apply(
    bodyColor: NetColors.textPrimary,
    displayColor: NetColors.textPrimary,
  );
  text = text.copyWith(
    headlineSmall: text.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleLarge: text.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: text.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: text.bodyLarge?.copyWith(fontSize: 16),
    bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
    bodySmall: text.bodySmall?.copyWith(fontSize: 12.5),
    labelLarge: text.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: text.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(NetRadius.md));
  const buttonPadding = EdgeInsets.symmetric(horizontal: NetSpacing.lg, vertical: NetSpacing.md);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: NetColors.background,
    // Botones: mínimo 48 dp (área táctil cómoda) y esquinas uniformes.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape, padding: buttonPadding),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        padding: buttonPadding,
        foregroundColor: NetColors.textPrimary,
        side: const BorderSide(color: NetColors.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: NetColors.accent),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: NetColors.surface,
      selectedColor: NetColors.selectedTint,
      side: const BorderSide(color: NetColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NetRadius.sm)),
      labelStyle: const TextStyle(fontSize: 13, color: NetColors.textPrimary),
      checkmarkColor: NetColors.accent,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: NetColors.textMuted,
        selectedForegroundColor: NetColors.accent,
        selectedBackgroundColor: NetColors.selectedTint,
        side: const BorderSide(color: NetColors.border),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: NetColors.surface,
      indicatorColor: NetColors.selectedTint,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: NetColors.surface,
      indicatorColor: NetColors.selectedTint,
      selectedIconTheme: IconThemeData(color: NetColors.accent),
      unselectedIconTheme: IconThemeData(color: NetColors.textMuted),
      selectedLabelTextStyle: TextStyle(color: NetColors.accent, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: NetColors.textMuted),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
      iconColor: NetColors.accent,
      collapsedIconColor: NetColors.textMuted,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NetColors.surfaceHigh,
      contentTextStyle: TextStyle(color: NetColors.textPrimary),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NetColors.accent,
      linearTrackColor: NetColors.border,
    ),
  );
}

/// Decoración común de los campos de texto (mismo estilo en toda la app).
InputDecoration netInput(String label, {String? hint, String? error}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetRadius.md),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: NetColors.background,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintStyle: const TextStyle(color: NetColors.textMuted),
    border: border(NetColors.border),
    enabledBorder: border(NetColors.border),
    focusedBorder: border(NetColors.accent, 2),
    errorBorder: border(NetColors.error),
    focusedErrorBorder: border(NetColors.error, 2),
    disabledBorder: border(NetColors.border),
  );
}
