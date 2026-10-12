import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/severity.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
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
        final total = controller.successCount + controller.failedTotal;
        return PageScaffold(
          children: [
            const ScreenHeader(title: 'NetLab', subtitle: 'Laboratorio de Redes'),
            // Red del dispositivo vs. acceso real al servidor: dos preguntas distintas.
            ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 2,
              children: [_connectivityCard(), _serverCard()],
            ),
            const SizedBox(height: NetSpacing.md),
            // Métricas reales de la sesión (sin datos de ejemplo).
            ResponsiveGrid(
              minItemWidth: 130,
              maxColumns: 4,
              children: [
                MetricTile(
                  label: 'Último tiempo HTTP',
                  value: last == null ? '—' : formatDuration(last.duration),
                  caption: last == null ? 'Sin solicitudes' : '${last.method} · ${last.client}',
                ),
                MetricTile(
                  label: 'Solicitudes',
                  value: '$total',
                  caption: 'en esta sesión',
                ),
                MetricTile(
                  label: 'Exitosas',
                  value: '${controller.successCount}',
                  severity: controller.successCount > 0 ? Severity.ok : Severity.neutral,
                  caption: 'HTTP 2xx',
                ),
                MetricTile(
                  label: 'Fallidas',
                  value: '${controller.failedTotal}',
                  severity: controller.failedTotal > 0 ? Severity.error : Severity.neutral,
                  caption: '${controller.httpErrorCount} HTTP · ${controller.failureCount} red',
                ),
              ],
            ),
            const SizedBox(height: NetSpacing.md),
            TwoPane(
              breakpoint: 760,
              firstFlex: 2,
              secondFlex: 3,
              first: PanelCard(
                title: 'Accesos rápidos',
                icon: Icons.bolt,
                child: Column(
                  children: [
                    ActionTile(
                      icon: Icons.http,
                      title: 'API REST',
                      subtitle: 'Enviar solicitudes HTTP',
                      onTap: () => onNavigate(1),
                    ),
                    const SizedBox(height: NetSpacing.sm),
                    ActionTile(
                      icon: Icons.network_check,
                      title: 'Diagnóstico',
                      subtitle: 'Probar red y servidor',
                      onTap: () => onNavigate(2),
                    ),
                    const SizedBox(height: NetSpacing.sm),
                    ActionTile(
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Revisar solicitudes pasadas',
                      onTap: () => onNavigate(3),
                    ),
                  ],
                ),
              ),
              second: PanelCard(
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
                    : Column(
                        children: [
                          for (var i = 0; i < recent.length; i++) ...[
                            if (i > 0) const Divider(height: 1, color: NetColors.border),
                            ActivityRow(entry: recent[i]),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _connectivityCard() {
    final snap = controller.snapshot;
    final offline = snap?.isOffline ?? false;
    return StatusCard(
      title: 'Red del dispositivo',
      icon: Icons.settings_input_antenna,
      headline: snap == null ? 'Comprobando…' : snap.label,
      headlineIcon: connectivityIcon(snap),
      severity: snap == null ? Severity.neutral : (offline ? Severity.error : Severity.ok),
      detail: 'Lo reporta el sistema operativo. Estar en una red no garantiza tener acceso a Internet.',
    );
  }

  Widget _serverCard() {
    final check = controller.lastCheck;
    final String headline;
    final Severity severity;
    String? detail;
    if (controller.checking && check == null) {
      headline = 'Comprobando servidor…';
      severity = Severity.neutral;
    } else if (check == null) {
      headline = 'Sin comprobar';
      severity = Severity.neutral;
      detail = 'Aún no se ha probado el acceso al servidor.';
    } else {
      headline = check.verdict.title;
      severity = check.verdict.severity;
      detail = '${check.verdict.detail}\n'
          'Última comprobación: ${formatTime(check.result.timestamp)} · ${formatDuration(check.result.duration)}';
    }
    return StatusCard(
      title: 'Servidor de pruebas',
      icon: Icons.dns_outlined,
      headline: headline,
      headlineIcon: check == null ? Icons.dns_outlined : outcomeIcon(check.result.outcome),
      severity: severity,
      loading: controller.checking && check == null,
      detail: detail,
      footer: Align(
        alignment: Alignment.centerLeft,
        child: PrimaryButton(
          label: 'Comprobar ahora',
          loadingLabel: 'Comprobando…',
          icon: Icons.refresh,
          loading: controller.checking,
          onPressed: () => controller.runServerCheck(),
        ),
      ),
    );
  }
}
