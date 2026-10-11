import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/severity.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller, required this.onNavigate});
  final NetLabController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final recent = controller.history.entries.take(5).toList();
        final last = controller.lastResult;
        return PageScaffold(
          children: [
            const ScreenHeader(title: 'NetLab', subtitle: 'Laboratorio de Redes'),
            ResponsivePair(
              first: _connectivityCard(),
              second: _serverCard(),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Último tiempo HTTP',
                    value: last == null ? '—' : formatDuration(last.duration),
                    caption: last == null ? 'Sin solicitudes' : '${last.method} · ${last.client}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Exitosas',
                    value: '${controller.successCount}',
                    severity: controller.successCount > 0 ? Severity.ok : Severity.neutral,
                    caption: 'HTTP 2xx',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Fallidas',
                    value: '${controller.failedTotal}',
                    severity: controller.failedTotal > 0 ? Severity.error : Severity.neutral,
                    caption:
                        '${controller.httpErrorCount} HTTP · ${controller.failureCount} red',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PanelCard(
              title: 'Módulos',
              icon: Icons.apps,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(Icons.http),
                    label: const Text('API REST'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => onNavigate(2),
                    icon: const Icon(Icons.network_check),
                    label: const Text('Diagnóstico'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => onNavigate(3),
                    icon: const Icon(Icons.history),
                    label: const Text('Historial'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PanelCard(
              title: 'Actividad reciente',
              icon: Icons.terminal,
              trailing: TextButton(
                onPressed: () => onNavigate(3),
                child: const Text('Ver todo'),
              ),
              child: recent.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'Aún no hay operaciones. Ejecuta una solicitud o una comprobación.',
                    )
                  : Column(children: [for (final e in recent) ActivityRow(entry: e)]),
            ),
          ],
        );
      },
    );
  }

  Widget _connectivityCard() {
    final snap = controller.snapshot;
    final offline = snap?.isOffline ?? false;
    return PanelCard(
      title: 'Conectividad del dispositivo',
      icon: Icons.settings_input_antenna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(connectivityIcon(snap),
                  size: 30, color: offline ? NetColors.error : NetColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    snap == null ? 'Comprobando…' : snap.label,
                    key: ValueKey(snap?.label),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lo reporta el sistema operativo. Estar en Wi-Fi no garantiza tener acceso a Internet.',
            style: TextStyle(color: NetColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _serverCard() {
    final check = controller.lastCheck;
    return PanelCard(
      title: 'Servidor de pruebas',
      icon: Icons.dns_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.checking && check == null)
            const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Comprobando servidor…'),
            ])
          else if (check == null)
            const StatusPill(label: 'Sin comprobar', severity: Severity.neutral)
          else ...[
            StatusPill(
              label: check.verdict.title,
              severity: check.verdict.severity,
              icon: outcomeIcon(check.result.outcome),
            ),
            const SizedBox(height: 8),
            Text(check.verdict.detail,
                style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Última comprobación: ${formatTime(check.result.timestamp)}'
              ' · ${formatDuration(check.result.duration)}',
              style: const TextStyle(color: NetColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: controller.checking ? null : () => controller.runServerCheck(),
            icon: controller.checking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: Text(controller.checking ? 'Comprobando…' : 'Comprobar ahora'),
          ),
        ],
      ),
    );
  }
}
