import 'package:flutter/material.dart';

import '../../core/config/endpoints.dart';
import '../../core/errors/net_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/api_result.dart';
import '../../services/diagnostics_service.dart';
import '../../services/dio_api_service.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, required this.controller});
  final NetLabController controller;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final _url = TextEditingController(text: Endpoints.healthCheck);
  bool _dioBusy = false;
  ApiResult? _dioResult;
  DioScenario? _dioScenario;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _runDio(DioScenario s) async {
    setState(() {
      _dioBusy = true;
      _dioScenario = s;
    });
    final result = await widget.controller.runDioScenario(s);
    if (!mounted) return;
    setState(() {
      _dioBusy = false;
      _dioResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return PageScaffold(
          children: [
            const ScreenHeader(
              title: 'Diagnóstico',
              subtitle: 'Conectividad del sistema y accesibilidad del servidor',
            ),
            _connectivityPanel(c),
            const SizedBox(height: 12),
            _serverPanel(c),
            const SizedBox(height: 12),
            _dioPanel(c),
          ],
        );
      },
    );
  }

  Widget _connectivityPanel(NetLabController c) {
    final snap = c.snapshot;
    return PanelCard(
      title: 'Conectividad reportada por el sistema',
      icon: Icons.settings_input_antenna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(connectivityIcon(snap),
                  color: (snap?.isOffline ?? false)
                      ? NetColors.error
                      : NetColors.accent),
              const SizedBox(width: 10),
              Text(snap?.label ?? 'Comprobando…',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Este dato proviene de connectivity_plus y NO prueba que haya Internet: '
            'puedes estar conectado a un Wi-Fi sin salida a la red.',
            style: TextStyle(color: NetColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('Cambios observados en esta sesión',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          if (c.events.isEmpty)
            const Text('Sin datos todavía.',
                style: TextStyle(color: NetColors.textMuted, fontSize: 12))
          else
            for (final e in c.events.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(formatTime(e.at),
                        style: monoStyle.copyWith(color: NetColors.textMuted)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(e.label,
                            style: const TextStyle(fontSize: 13))),
                    if (e.initial)
                      const Text('estado inicial',
                          style: TextStyle(
                              color: NetColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _serverPanel(NetLabController c) {
    final check = c.lastCheck;
    return PanelCard(
      title: 'Prueba de acceso al servidor (HTTPS)',
      icon: Icons.dns_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: netInput('URL a comprobar'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                c.checking ? null : () => c.runServerCheck(url: _url.text),
            icon: c.checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_ping),
            label: Text(c.checking
                ? 'Comprobando…'
                : (check == null ? 'Ejecutar prueba' : 'Ejecutar de nuevo')),
          ),
          const SizedBox(height: 12),
          if (check == null && !c.checking)
            const EmptyState(
                icon: Icons.dns_outlined,
                message: 'Aún no se ha ejecutado ninguna prueba.')
          else if (check != null)
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    label: check.verdict.title,
                    severity: check.verdict.severity,
                    icon: outcomeIcon(check.result.outcome),
                  ),
                  const SizedBox(height: 8),
                  Text(check.verdict.detail),
                  const SizedBox(height: 8),
                  KeyValueRow(
                      'Fecha y hora', formatDateTime(check.result.timestamp)),
                  KeyValueRow('Código HTTP',
                      check.result.statusCode?.toString() ?? 'Sin respuesta'),
                  KeyValueRow(
                      'Tiempo HTTP', formatDuration(check.result.duration)),
                  if (check.latency != null)
                    KeyValueRow('Clasificación', check.latency!.label),
                  KeyValueRow('URL', check.result.url),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'El tiempo mostrado es el tiempo de respuesta HTTP (petición completa), no un ping ICMP. '
            'Tampoco es una medición de velocidad de descarga o subida.',
            style: TextStyle(color: NetColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _dioPanel(NetLabController c) {
    return PanelCard(
      title: 'Depuración avanzada con Dio',
      icon: Icons.bug_report_outlined,
      trailing: TextButton(
        onPressed: c.dioLog.isEmpty ? null : c.clearDioLog,
        child: const Text('Limpiar trazas'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cada botón lanza una petición real con Dio. Un interceptor registra método, URL (sin query), '
            'código y duración; nunca encabezados ni cuerpos.',
            style: TextStyle(color: NetColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in DioScenario.values)
                OutlinedButton(
                  onPressed: _dioBusy ? null : () => _runDio(s),
                  child: Text(s.label),
                ),
            ],
          ),
          if (_dioBusy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
          if (_dioResult != null && _dioScenario != null) ...[
            const SizedBox(height: 10),
            Text(_dioScenario!.description,
                style:
                    const TextStyle(color: NetColors.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: StatusPill(
                label: _dioResult!.hasResponse
                    ? 'HTTP ${_dioResult!.statusCode} · ${formatDuration(_dioResult!.duration)}'
                    : '${_dioResult!.errorType?.title ?? 'Error'} · ${formatDuration(_dioResult!.duration)}',
                severity: outcomeSeverity(_dioResult!.outcome),
                icon: outcomeIcon(_dioResult!.outcome),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 70, maxHeight: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NetColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NetColors.border),
            ),
            child: c.dioLog.isEmpty
                ? const Text('Aún no hay trazas. Ejecuta un escenario.',
                    style: TextStyle(color: NetColors.textMuted, fontSize: 12))
                : SingleChildScrollView(
                    child:
                        SelectableText(c.dioLog.join('\n'), style: monoStyle),
                  ),
          ),
        ],
      ),
    );
  }
}
