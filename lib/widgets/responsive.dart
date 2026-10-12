import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum ScreenClass { compact, medium, expanded }

/// Puntos de quiebre (Material 3): <600 móvil, 600–1023 tableta, ≥1024 pantalla grande.
class Breakpoints {
  Breakpoints._();
  static const double medium = 600;
  static const double expanded = 1024;

  static ScreenClass of(double width) => width >= expanded
      ? ScreenClass.expanded
      : (width >= medium ? ScreenClass.medium : ScreenClass.compact);
}

/// Construye según el ancho DISPONIBLE (no el de la pantalla completa).
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.builder});
  final Widget Function(BuildContext context, ScreenClass cls, double width) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => builder(context, Breakpoints.of(c.maxWidth), c.maxWidth),
      );
}

/// Rejilla adaptable: calcula cuántas columnas caben según [minItemWidth].
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.maxColumns = 4,
    this.spacing = NetSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final fit = ((w + spacing) / (minItemWidth + spacing)).floor();
      final cols = math.max(1, math.min(maxColumns, fit));
      final itemWidth = (w - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final ch in children) SizedBox(width: itemWidth, child: ch)],
      );
    });
  }
}

/// Dos paneles en paralelo si hay ancho suficiente; si no, apilados.
class TwoPane extends StatelessWidget {
  const TwoPane({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 820,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;
  final int firstFlex;
  final int secondFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: NetSpacing.lg),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      }
      return Column(children: [first, const SizedBox(height: NetSpacing.md), second]);
    });
  }
}

/// Fila de chips: desplazable en móvil, con salto de línea en pantallas anchas.
class AdaptiveChipRow extends StatelessWidget {
  const AdaptiveChipRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < Breakpoints.medium) {
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: NetSpacing.sm),
            itemBuilder: (_, i) => Center(child: children[i]),
          ),
        );
      }
      return Wrap(spacing: NetSpacing.sm, runSpacing: NetSpacing.sm, children: children);
    });
  }
}
