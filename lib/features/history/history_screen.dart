import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/api_result.dart';
import '../../services/history_service.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/responsive.dart';

/// Historial. Móvil: tarjetas. Ancho ≥ 720 dp: filas con columnas alineadas.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});
  final NetLabController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _kinds = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'DIAGNÓSTICO', 'DIO'];
  String? _kind;
  Outcome? _outcome;

  Future<void> _confirmClear() async {
    final ok = await confirmDialog(
      context,
      title: 'Limpiar historial',
      message: 'Se borrarán todos los registros de esta sesión. Esta acción no se puede deshacer.',
      confirmLabel: 'Limpiar',
    );
    if (ok) widget.controller.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final all = widget.controller.history.entries;
        final shown = HistoryService.apply(all, kind: _kind, outcome: _outcome);
        return PageScaffold(
          children: [
            ScreenHeader(
              title: 'Historial',
              subtitle: '${shown.length} de ${all.length} registros de la sesión',
              trailing: IconButton(
                tooltip: 'Limpiar historial',
                onPressed: all.isEmpty ? null : _confirmClear,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
            AdaptiveChipRow(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _kind == null,
                  onSelected: (_) => setState(() => _kind = null),
                ),
                for (final k in _kinds)
                  ChoiceChip(
                    label: Text(k),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = _kind == k ? null : k),
                  ),
              ],
            ),
            const SizedBox(height: NetSpacing.xs),
            AdaptiveChipRow(
              children: [
                ChoiceChip(
                  label: const Text('Cualquier resultado'),
                  selected: _outcome == null,
                  onSelected: (_) => setState(() => _outcome = null),
                ),
                for (final o in Outcome.values)
                  ChoiceChip(
                    label: Text(o.label),
                    selected: _outcome == o,
                    onSelected: (_) => setState(() => _outcome = _outcome == o ? null : o),
                  ),
              ],
            ),
            const SizedBox(height: NetSpacing.lg),
            if (all.isEmpty)
              const PanelCard(
                child: EmptyState(
                  icon: Icons.history,
                  message: 'El historial está vacío. Las solicitudes y comprobaciones reales aparecerán aquí.',
                ),
              )
            else if (shown.isEmpty)
              const PanelCard(
                child: EmptyState(icon: Icons.filter_alt_off_outlined, message: 'Ningún registro coincide con los filtros.'),
              )
            else
              ResponsiveLayout(
                builder: (context, cls, width) {
                  final wide = width >= 720;
                  return Column(
                    children: [
                      if (wide) const HistoryTableHeader(),
                      for (final e in shown) HistoryDetailTile(entry: e, wide: wide),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
