import 'package:flutter/material.dart';

import '../../core/config/endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/json_utils.dart';
import '../../models/api_result.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/responsive.dart';
import 'request_editor.dart';
import 'response_viewer.dart';

/// Explorador REST. Móvil: solicitud arriba, respuesta abajo.
/// Con ≥ 860 dp disponibles: solicitud y respuesta lado a lado.
class ApiExplorerScreen extends StatefulWidget {
  const ApiExplorerScreen({super.key, required this.controller, this.onOpenHistory});
  final NetLabController controller;
  final VoidCallback? onOpenHistory;

  @override
  State<ApiExplorerScreen> createState() => _ApiExplorerScreenState();
}

class _ApiExplorerScreenState extends State<ApiExplorerScreen> {
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

  bool get _hasBody => _method == 'POST' || _method == 'PUT' || _method == 'PATCH';

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

  void _formatBody() {
    final pretty = JsonUtils.tryPretty(_body.text);
    setState(() {
      if (pretty != null) {
        _body.text = pretty;
        _inputError = null;
      } else {
        _inputError = JsonUtils.validate(_body.text) ?? 'No se pudo formatear el JSON.';
      }
    });
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
    if (_method == 'DELETE') {
      final ok = await confirmDialog(
        context,
        title: 'Confirmar DELETE',
        message: 'Se enviará una solicitud DELETE real a:\n${_url.text.trim()}',
        confirmLabel: 'Enviar DELETE',
      );
      if (!ok) return;
    }
    if (!mounted) return;

    // 2) Ejecución asíncrona: la interfaz sigue respondiendo.
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

  Widget _responsePane() {
    final Widget child;
    if (_loading) {
      child = const PanelCard(key: ValueKey('loading'), child: LoadingState(message: 'Esperando respuesta del servidor…'));
    } else if (_result == null) {
      child = const PanelCard(
        key: ValueKey('empty'),
        title: 'Respuesta',
        icon: Icons.inbox_outlined,
        child: EmptyState(
          icon: Icons.http,
          message: 'Elige un ejemplo y pulsa Enviar para ver la respuesta real del servidor.',
        ),
      );
    } else {
      child = ResponseViewer(
        key: ValueKey(_result.hashCode),
        result: _result!,
        onRetry: _send,
        retryEnabled: !_loading,
      );
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: child);
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
              : IconButton(tooltip: 'Ver historial', onPressed: widget.onOpenHistory, icon: const Icon(Icons.history)),
        ),
        AdaptiveChipRow(
          children: [
            for (final e in Endpoints.examples)
              ActionChip(label: Text(e.title), tooltip: e.description, onPressed: () => _loadExample(e)),
          ],
        ),
        const SizedBox(height: NetSpacing.lg),
        TwoPane(
          breakpoint: 860,
          first: RequestEditor(
            method: _method,
            onMethodChanged: (m) => setState(() => _method = m),
            urlController: _url,
            headersController: _headers,
            bodyController: _body,
            hasBody: _hasBody,
            loading: _loading,
            onSend: _send,
            onCancel: _cancel,
            onFormatBody: _formatBody,
            onClearBody: () => setState(() => _body.clear()),
            inputError: _inputError,
            notice: _notice,
          ),
          second: _responsePane(),
        ),
      ],
    );
  }
}
