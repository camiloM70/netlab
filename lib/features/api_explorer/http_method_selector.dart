import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Selector visual de método HTTP. Usa Wrap: nunca desborda aunque el ancho sea 320.
class HttpMethodSelector extends StatelessWidget {
  const HttpMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.methods = const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> methods;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NetSpacing.sm,
      runSpacing: NetSpacing.sm,
      children: [
        for (final m in methods)
          _MethodButton(method: m, selected: m == selected, onTap: () => onChanged(m)),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({required this.method, required this.selected, required this.onTap});
  final String method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = methodColor(method);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Método $method',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? color.withAlpha(36) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetRadius.md),
            side: BorderSide(color: selected ? color : NetColors.border, width: selected ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(NetRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NetSpacing.md),
                  child: Text(
                    method,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: selected ? color : NetColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
