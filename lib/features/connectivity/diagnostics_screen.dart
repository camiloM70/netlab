import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/endpoints.dart';
import '../../core/errors/net_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/api_result.dart';
import '../../models/connectivity_snapshot.dart';
import '../../models/severity.dart';
import '../../services/diagnostics_service.dart';
import '../../services/dio_api_service.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
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
              subtitle: 'Red del dispositivo y acceso real al servidor',
            ),
            _networkVsInternet(c),
            const SizedBox(height: NetSpacing.lg),
            // Pantallas anchas: prueba del servidor a la izquierda, Dio a la derecha.
            TwoPane(
              breakpoint: 900,
              first: _serverPanel(c),
              second: _dioPanel(c),
            ),
            const SizedBox(height: NetSpacing.lg),
            _eventsPanel(c),
          ],
        );
      },
    );
  }

  /// Diferencia clave: estar en una red ≠ tener acceso al servicio.
  Widget _networkVsInternet(NetLabController c) {
    final snap = c.snapshot;
    final offline = snap?.isOffline ?? false;
    final check = c.lastCheck;
    final reached = check?.result.hasResponse ?? false;
    return ResponsiveGrid(
      minItemWidth: 300,
      maxColumns: 2,
      children: [
        StatusCard(
          title: '1 · Red del dispositivo (la reporta el sistema)',
          icon: Icons.settings_input_antenna,
          headline: snap == null ? 'Comprobando…' : snap.label,
          headlineIcon: connectivityIcon(snap),
          severity: snap == null
              ? Severity.neutral
              : (offline ? Severity.error : Severity.ok),
          detail:
              'Dato de connectivity_plus. Android informa del tipo de red activa; '
              'no indica la intensidad de señal ni si hay salida a Internet.',
          footer: (snap == null || snap.isOffline)
              ? null
              : Wrap(
                  spacing: NetSpacing.sm,
                  runSpacing: NetSpacing.sm,
                  children: [
                    for (final r in snap.active)
                      StatusPill(
                          label: connectivityName(r), severity: Severity.info),
                  ],
                ),
        ),
        StatusCard(
          title: '2 · Acceso real al servicio (petición HTTP)',
          icon: Icons.public,
          headline: check == null
              ? (c.checking ? 'Comprobando…' : 'Sin comprobar')
              : check.verdict.title,
          headlineIcon:
              check == null ? Icons.public : outcomeIcon(check.result.outcome),
          severity: check == null ? Severity.neutral : check.verdict.severity,
          loading: c.checking && check == null,
          detail: check == null
              ? 'Ejecuta la prueba para saber si el servidor responde.'
              : (reached
                  ? 'El servidor respondió: hay ruta real hasta el servicio.'
                  : 'No hubo respuesta HTTP. Puedes estar conectado a una red sin salida a Internet.'),
        ),
      ],
    );
  }

  Widget _serverPanel(NetLabController c) {
    final check = c.lastCheck;
    return PanelCard(
      title: 'Prueba de acceso al servidor',
      icon: Icons.dns_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: 3,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: netInput('URL a comprobar'),
          ),
          const SizedBox(height: NetSpacing.md),
          PrimaryButton(
            label: check == null ? 'Ejecutar prueba' : 'Ejecutar de nuevo',
            loadingLabel: 'Comprobando…',
            icon: Icons.network_ping,
            loading: c.checking,
            onPressed: () => c.runServerCheck(url: _url.text),
          ),
          const SizedBox(height: NetSpacing.lg),
          if (check == null && c.checking)
            const LoadingState(message: 'Comprobando servidor…')
          else if (check == null)
            const EmptyState(
                icon: Icons.dns_outlined,
                message: 'Aún no se ha ejecutado ninguna prueba.')
          else ...[
            Semantics(
              liveRegion: true,
              child: Text(check.verdict.detail),
            ),
            const SizedBox(height: NetSpacing.md),
            ResponsiveGrid(
              minItemWidth: 120,
              maxColumns: 3,
              children: [
                MetricTile(
                  filled: true,
                  label: 'Código HTTP',
                  value: check.result.statusCode?.toString() ?? '—',
                  severity: outcomeSeverity(check.result.outcome),
                ),
                MetricTile(
                    filled: true,
                    label: 'Tiempo HTTP',
                    value: formatDuration(check.result.duration)),
                MetricTile(
                  filled: true,
                  label: 'Clasificación',
                  value: check.latency?.label ?? '—',
                  severity: switch (check.latency) {
                    LatencyClass.fast => Severity.ok,
                    LatencyClass.acceptable => Severity.warn,
                    LatencyClass.slow => Severity.error,
                    null => Severity.neutral,
                  },
                ),
              ],
            ),
            const SizedBox(height: NetSpacing.md),
            KeyValueRow('Fecha y hora', formatDateTime(check.result.timestamp)),
            KeyValueRow('URL', check.result.url),
          ],
          const SizedBox(height: NetSpacing.md),
          Text(
            'El tiempo mostrado es el de la petición HTTP completa, no un ping ICMP, '
            'ni una medición de velocidad de descarga o subida.',
            style: NetText.muted(context, size: 11.5),
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
        child: const Text('Limpiar'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cada botón lanza una petición real con Dio. Un interceptor registra método, '
            'URL (sin query), código y duración; nunca encabezados ni cuerpos.',
            style: NetText.muted(context),
          ),
          const SizedBox(height: NetSpacing.md),
          Wrap(
            spacing: NetSpacing.sm,
            runSpacing: NetSpacing.sm,
            children: [
              for (final s in DioScenario.values)
                OutlinedButton(
                    onPressed: _dioBusy ? null : () => _runDio(s),
                    child: Text(s.label)),
            ],
          ),
          if (_dioBusy) ...[
            const SizedBox(height: NetSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (_dioResult != null && _dioScenario != null) ...[
            const SizedBox(height: NetSpacing.md),
            Text(_dioScenario!.description, style: NetText.muted(context)),
            const SizedBox(height: NetSpacing.sm),
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
          const SizedBox(height: NetSpacing.md),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72, maxHeight: 220),
            padding: const EdgeInsets.all(NetSpacing.md),
            decoration: BoxDecoration(
              color: NetColors.background,
              borderRadius: BorderRadius.circular(NetRadius.md),
              border: Border.all(color: NetColors.border),
            ),
            child: c.dioLog.isEmpty
                ? Text('Aún no hay trazas. Ejecuta un escenario.',
                    style: NetText.muted(context))
                : SingleChildScrollView(
                    child:
                        SelectableText(c.dioLog.join('\n'), style: monoStyle)),
          ),
        ],
      ),
    );
  }

  Widget _eventsPanel(NetLabController c) {
    return PanelCard(
      title: 'Cambios de conectividad observados en esta sesión',
      icon: Icons.timeline,
      child: c.events.isEmpty
          ? Text('Sin datos todavía.', style: NetText.muted(context))
          : Column(
              children: [
                for (final ConnectivitySnapshot e in c.events.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(connectivityIcon(e),
                            size: 16,
                            color: e.isOffline
                                ? NetColors.error
                                : NetColors.accent),
                        const SizedBox(width: NetSpacing.sm),
                        Text(formatTime(e.at),
                            style:
                                monoStyle.copyWith(color: NetColors.textMuted)),
                        const SizedBox(width: NetSpacing.md),
                        Expanded(
                            child:
                                Text(e.label, overflow: TextOverflow.ellipsis)),
                        if (e.initial)
                          Text('inicial',
                              style: NetText.muted(context, size: 11)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
