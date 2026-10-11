import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/severity.dart';

/// Contenedor de página: área segura, ancho máximo y desplazamiento.
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: children,
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: NetColors.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tarjeta con borde discreto y esquinas redondeadas.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NetColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NetColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: NetColors.accent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: NetColors.textMuted)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Etiqueta de estado con color según gravedad.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.severity, this.icon});
  final String label;
  final Severity severity;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = severity.color;
    return Semantics(
      label: 'Estado: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withAlpha(34),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(110)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.caption, this.severity = Severity.neutral});
  final String label;
  final String value;
  final String? caption;
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NetColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NetColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: NetColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: severity == Severity.neutral
                          ? NetColors.textPrimary
                          : severity.color)),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(caption!,
                    style: const TextStyle(
                        color: NetColors.textMuted, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: NetColors.textMuted),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: NetColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: NetColors.textMuted, fontSize: 13)),
          ),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Muestra dos tarjetas en fila si hay ancho suficiente; si no, en columna.
class ResponsivePair extends StatelessWidget {
  const ResponsivePair({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 620) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      }
      return Column(children: [first, const SizedBox(height: 12), second]);
    });
  }
}
