import 'package:flutter/material.dart';

import '../../models/severity.dart';

/// Paleta de NetLab: azul marino oscuro con acentos azul eléctrico y cian.
class NetColors {
  NetColors._();

  static const background = Color(0xFF070D1F);
  static const surface = Color(0xFF0F1A36);
  static const surfaceHigh = Color(0xFF16244A);
  static const border = Color(0xFF223161);
  static const primary = Color(0xFF2F6BFF);
  static const accent = Color(0xFF22D3EE);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFE6ECFF);
  static const textMuted = Color(0xFF8FA0C8);
}

const TextStyle monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas', 'Courier'],
  fontSize: 12.5,
  height: 1.4,
  color: NetColors.textPrimary,
);

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
    secondary: NetColors.accent,
    surface: NetColors.surface,
    error: NetColors.error,
    onSurface: NetColors.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NetColors.background,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: NetColors.surface,
      indicatorColor: Color(0x442F6BFF),
    ),
  );
}

/// Decoración común para los campos de texto.
InputDecoration netInput(String label, {String? hint, String? error}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    filled: true,
    fillColor: NetColors.background,
    border: border(NetColors.border),
    enabledBorder: border(NetColors.border),
    focusedBorder: border(NetColors.accent),
    disabledBorder: border(NetColors.border),
  );
}
