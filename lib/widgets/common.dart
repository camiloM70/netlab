import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/severity.dart';
import 'responsive.dart';

/// Contenedor de página: área segura, ancho máximo, relleno adaptable y
/// desplazamiento. El teclado cierra al arrastrar.
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.children, this.maxWidth = 1100});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, c) {
        final pad = switch (Breakpoints.of(c.maxWidth)) {
          ScreenClass.compact => NetSpacing.lg,
          ScreenClass.medium => NetSpacing.xl,
          ScreenClass.expanded => NetSpacing.xxl,
        };
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + NetSpacing.sm),
              children: children,
            ),
          ),
        );
      }),
    );
  }
}

/// Encabezado de pantalla (título, subtítulo y acción opcional).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader(
      {super.key, required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NetSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: NetText.muted(context, size: 14)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tarjeta con borde sutil; [accent] añade una franja lateral de color de estado.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.accent,
    this.padding = const EdgeInsets.all(NetSpacing.lg),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding:
          accent == null ? padding : padding.copyWith(left: padding.left + 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: NetColors.accent),
                  const SizedBox(width: NetSpacing.sm),
                ],
                Expanded(
                  child: Text(title!,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: NetColors.textMuted)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: NetSpacing.md),
          ],
          child,
        ],
      ),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: NetColors.surface,
        borderRadius: BorderRadius.circular(NetRadius.lg),
        border: Border.all(color: NetColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NetRadius.lg - 1),
        child: Stack(
          children: [
            content,
            if (accent != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: accent!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de estado: icono + titular grande + detalle + pie opcional.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headline,
    required this.severity,
    this.headlineIcon,
    this.detail,
    this.footer,
    this.loading = false,
  });

  final String title;
  final IconData icon;
  final String headline;
  final Severity severity;
  final IconData? headlineIcon;
  final String? detail;
  final Widget? footer;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: title,
      icon: icon,
      accent: severity == Severity.neutral ? null : severity.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loading)
                const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
              else
                Icon(headlineIcon ?? icon, size: 28, color: severity.color),
              const SizedBox(width: NetSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(headline,
                      key: ValueKey(headline),
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: NetSpacing.sm),
            Text(detail!, style: NetText.muted(context)),
          ],
          if (footer != null) ...[
            const SizedBox(height: NetSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Etiqueta de estado con color según gravedad.
class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key, required this.label, required this.severity, this.icon});
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

/// Insignia del método HTTP o tipo de prueba.
class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});
  final String method;

  @override
  Widget build(BuildContext context) {
    final color = methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(NetRadius.sm),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(method,
          maxLines: 1,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.3)),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.severity = Severity.neutral,
    this.filled = false,
  });
  final String label;
  final String value;
  final String? caption;
  final Severity severity;

  /// true: fondo elevado (para usar dentro de otra tarjeta).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(NetSpacing.md + 2),
          decoration: BoxDecoration(
            color: filled ? NetColors.surfaceHigh : NetColors.surface,
            borderRadius: BorderRadius.circular(NetRadius.md),
            border: Border.all(color: NetColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NetText.muted(context, size: 12)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          color: severity == Severity.neutral
                              ? NetColors.textPrimary
                              : severity.color,
                        )),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(caption!, style: NetText.muted(context, size: 11.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón principal con estado de carga (deshabilitado mientras carga).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text(loading ? (loadingLabel ?? label) : label),
    );
  }
}

/// Fila de acceso rápido (icono, título, subtítulo, flecha). Área táctil ≥ 56 dp.
class ActionTile extends StatelessWidget {
  const ActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NetColors.surfaceHigh,
      borderRadius: BorderRadius.circular(NetRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(NetRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: NetSpacing.md, vertical: NetSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NetColors.selectedTint,
                    borderRadius: BorderRadius.circular(NetRadius.sm),
                  ),
                  child: Icon(icon, color: NetColors.accent, size: 22),
                ),
                const SizedBox(width: NetSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(subtitle, style: NetText.muted(context, size: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: NetColors.textMuted),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(
          vertical: NetSpacing.xl, horizontal: NetSpacing.md),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: NetColors.textMuted),
            const SizedBox(height: NetSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: NetText.muted(context, size: 14)),
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NetSpacing.xl),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: NetSpacing.md),
              Text(message, style: NetText.muted(context, size: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.tip,
    this.footnote,
    this.onRetry,
  });
  final String title;
  final String message;
  final String? tip;
  final String? footnote;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
              label: title,
              severity: Severity.error,
              icon: Icons.error_outline),
          const SizedBox(height: NetSpacing.md),
          Text(message),
          if (tip != null) ...[
            const SizedBox(height: NetSpacing.sm),
            Text(tip!, style: NetText.muted(context)),
          ],
          if (footnote != null) ...[
            const SizedBox(height: NetSpacing.xs),
            Text(footnote!, style: NetText.muted(context)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: NetSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
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
              width: 104,
              child: Text(label, style: NetText.muted(context, size: 13))),
          Expanded(
              child:
                  SelectableText(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
