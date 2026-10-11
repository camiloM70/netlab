import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/endpoints.dart';
import '../../core/errors/net_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/http_status.dart';
import '../../core/utils/json_utils.dart';
import '../../models/api_result.dart';
import '../../models/severity.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';

class ApiExplorerScreen extends StatefulWidget {
  const ApiExplorerScreen({super.key, required this.controller, this.onOpenHistory});
  final NetLabController controller;
  final VoidCallback? onOpenHistory;

  @override
  State<ApiExplorerScreen> createState() => _ApiExplorerScreenState();
}

class _ApiExplorerScreenState extends State<ApiExplorerScreen> {
  static const _methods = ['GET', 'POST', 'PUT', 'DELETE'];
  static const _maxChars = 20000; // límite de texto mostrado en pantalla

  final _url = TextEditingController(text: Endpoints.examples.first.url);
  final _headers = TextEditingController();
  final _body = TextEditingController();

  String _method = 'GET';
  bool _loading = false;
  int _runId = 0; // identifica la solicitud vigente (para cancelar/ignorar)
  ApiResult? _result;
  String? _inputError;
  String? _notice;

  @override
  void dispose() {
    _url.dispose();
    _headers.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _hasBody => _method == 'POST' || _method == 'PUT';

  void _loadExample(RequestExample e) {
    setState(() {
      _method = e.method;
      _url.text = e.url;
      _headers.text = e.headers ?? '';
      _body.text = e.body ?? '';
      _inputError = null;
      _notice = e.description;
    });
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar DELETE'),
        content: Text('Se enviará una solicitud DELETE real a:\n${_url.text.trim()}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar DELETE')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _send() async {
    // 1) Validación local antes de tocar la red.
    final Map<String, String> headers;
    try {
      headers = JsonUtils.parseHeaders(_headers.text);
    } on FormatException catch (e) {
      setState(() => _inputError = e.message);
      return;
    }
    String? body;
    if (_hasBody && _body.text.trim().isNotEmpty) {
      final err = JsonUtils.validate(_body.text);
      if (err != null) {
        setState(() => _inputError = err);
        return;
      }
      body = _body.text;
    }
    if (_method == 'DELETE' && !await _confirmDelete()) return;
    if (!mounted) return;

    // 2) Ejecución. La interfaz sigue respondiendo (es asíncrona).
    final id = ++_runId;
    setState(() {
      _loading = true;
      _inputError = null;
      _notice = null;
    });
    final result = await widget.controller.sendRequest(
      method: _method,
      url: _url.text,
      headers: headers,
      body: body,
    );
    // Si el usuario canceló o lanzó otra solicitud, se ignora esta respuesta.
    if (!mounted || id != _runId) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  void _cancel() {
    _runId++;
    setState(() {
      _loading = false;
      _notice = 'Solicitud cancelada. Si el servidor responde, la respuesta se ignora '
          '(la conexión no se aborta, pero queda registrada en el historial).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        ScreenHeader(
          title: 'API REST',
          subtitle: 'Solicitudes HTTP reales con el paquete http',
          trailing: widget.onOpenHistory == null
              ? null
              : IconButton(
                  tooltip: 'Ver historial',
                  onPressed: widget.onOpenHistory,
                  icon: const Icon(Icons.history),
                ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Endpoints.examples.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final e = Endpoints.examples[i];
              return ActionChip(
                label: Text(e.title),
                tooltip: e.description,
                onPressed: () => _loadExample(e),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        PanelCard(
          title: 'Solicitud',
          icon: Icons.send_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final m in _methods) ButtonSegment(value: m, label: Text(m)),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: netInput('URL del endpoint', hint: 'https://…'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _headers,
                maxLines: 2,
                minLines: 1,
                autocorrect: false,
                style: monoStyle,
                decoration: netInput('Encabezados (JSON, opcional)',
                    hint: '{"Accept": "application/json"}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                enabled: _hasBody,
                maxLines: 7,
                minLines: 4,
                autocorrect: false,
                style: monoStyle,
                decoration: netInput(
                  _hasBody ? 'Cuerpo JSON' : 'Cuerpo JSON (solo POST y PUT)',
                ),
              ),
              if (_inputError != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(_inputError!,
                      style: const TextStyle(color: NetColors.error, fontSize: 13)),
                ),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 10),
                Text(_notice!,
                    style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_loading ? 'Enviando…' : 'Enviar'),
                  ),
                  if (_loading) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(onPressed: _cancel, child: const Text('Cancelar')),
                  ],
                ],
              ),
              if (_loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_result == null)
          const PanelCard(
            child: EmptyState(
              icon: Icons.http,
              message: 'Elige un ejemplo y pulsa Enviar para ver la respuesta real del servidor.',
            ),
          )
        else
          _ResultPanel(result: _result!, maxChars: _maxChars, onRetry: _send, retryEnabled: !_loading),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.maxChars,
    required this.onRetry,
    required this.retryEnabled,
  });

  final ApiResult result;
  final int maxChars;
  final VoidCallback onRetry;
  final bool retryEnabled;

  @override
  Widget build(BuildContext context) {
    if (!result.hasResponse) return _failure(context);

    final code = result.statusCode!;
    final sev = outcomeSeverity(result.outcome);
    final note = persistenceNote(result.method, result.url, code);
    final shown = result.displayBody;
    final truncated = shown.length > maxChars;
    return PanelCard(
      title: 'Respuesta',
      icon: Icons.inbox_outlined,
      trailing: IconButton(
        tooltip: 'Copiar respuesta',
        icon: const Icon(Icons.copy),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(ClipboardData(text: shown));
          messenger.showSnackBar(const SnackBar(content: Text('Respuesta copiada')));
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '$code ${result.reasonPhrase ?? ''}'.trim(),
                severity: sev,
                icon: outcomeIcon(result.outcome),
              ),
              StatusPill(
                  label: formatDuration(result.duration),
                  severity: Severity.info,
                  icon: Icons.timer_outlined),
              StatusPill(
                  label: formatBytes(result.sizeBytes),
                  severity: Severity.neutral,
                  icon: Icons.data_object),
            ],
          ),
          const SizedBox(height: 10),
          Text(describeStatus(code),
              style: const TextStyle(color: NetColors.textMuted, fontSize: 13)),
          if (result.outcome == Outcome.httpError) ...[
            const SizedBox(height: 6),
            const Text(
              'La petición llegó al servidor y recibió una respuesta HTTP válida: no es un fallo de red.',
              style: TextStyle(color: NetColors.warning, fontSize: 12),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NetColors.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NetColors.warning.withAlpha(90)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: NetColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(note, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          ],
          if (result.headers.isNotEmpty)
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: EdgeInsets.zero,
              title: Text('Encabezados de respuesta (${result.headers.length})',
                  style: const TextStyle(fontSize: 14)),
              children: [
                for (final e in result.headers.entries) KeyValueRow(e.key, e.value),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            switch (result.bodyKind) {
              BodyKind.json => 'Cuerpo (JSON)',
              BodyKind.text => 'Cuerpo (texto, no es JSON)',
              BodyKind.empty => 'Cuerpo vacío',
            },
            style: const TextStyle(color: NetColors.textMuted, fontSize: 12),
          ),
          if (result.bodyKind != BodyKind.empty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 360),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NetColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NetColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  truncated ? shown.substring(0, maxChars) : shown,
                  style: monoStyle,
                ),
              ),
            ),
            if (truncated)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Respuesta truncada en pantalla; el botón Copiar copia el texto completo.',
                  style: TextStyle(color: NetColors.textMuted, fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _failure(BuildContext context) {
    final type = result.errorType ?? NetErrorType.unexpected;
    return PanelCard(
      title: 'Sin respuesta del servidor',
      icon: Icons.cloud_off,
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(label: type.title, severity: Severity.error, icon: Icons.error_outline),
            const SizedBox(height: 10),
            Text(result.errorMessage ?? type.tip),
            const SizedBox(height: 6),
            Text(type.tip, style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Tras ${formatDuration(result.duration)}',
                style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: retryEnabled ? onRetry : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
