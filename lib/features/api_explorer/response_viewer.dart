import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/net_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/http_status.dart';
import '../../models/api_result.dart';
import '../../models/severity.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';

/// Muestra una respuesta real: estado, tiempo, tamaño, y pestañas Cuerpo/Encabezados.
class ResponseViewer extends StatefulWidget {
  const ResponseViewer({
    super.key,
    required this.result,
    required this.onRetry,
    required this.retryEnabled,
    this.maxChars = 20000,
  });

  final ApiResult result;
  final VoidCallback onRetry;
  final bool retryEnabled;
  final int maxChars; // límite de texto dibujado (el botón Copiar copia todo)

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer> {
  int _tab = 0; // 0 = cuerpo, 1 = encabezados

  ApiResult get r => widget.result;

  @override
  Widget build(BuildContext context) {
    if (!r.hasResponse) return _failure();

    final code = r.statusCode!;
    final note = persistenceNote(r.method, r.url, code);
    return PanelCard(
      title: 'Respuesta',
      icon: Icons.inbox_outlined,
      accent: outcomeSeverity(r.outcome).color,
      trailing: IconButton(
        tooltip: 'Copiar cuerpo de la respuesta',
        icon: const Icon(Icons.copy),
        onPressed: r.bodyKind == BodyKind.empty ? null : _copy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: NetSpacing.sm,
            runSpacing: NetSpacing.sm,
            children: [
              StatusPill(
                label: '$code ${r.reasonPhrase ?? ''}'.trim(),
                severity: outcomeSeverity(r.outcome),
                icon: outcomeIcon(r.outcome),
              ),
              StatusPill(label: formatDuration(r.duration), severity: Severity.info, icon: Icons.timer_outlined),
              StatusPill(label: formatBytes(r.sizeBytes), severity: Severity.neutral, icon: Icons.data_object),
            ],
          ),
          const SizedBox(height: NetSpacing.md),
          Text(describeStatus(code), style: NetText.muted(context, size: 13)),
          if (r.outcome == Outcome.httpError) ...[
            const SizedBox(height: NetSpacing.sm),
            const Text(
              'La petición llegó al servidor y recibió una respuesta HTTP válida: no es un fallo de red.',
              style: TextStyle(color: NetColors.warning, fontSize: 12.5),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: NetSpacing.md),
            Container(
              padding: const EdgeInsets.all(NetSpacing.md),
              decoration: BoxDecoration(
                color: NetColors.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(NetRadius.md),
                border: Border.all(color: NetColors.warning.withAlpha(90)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: NetColors.warning),
                  const SizedBox(width: NetSpacing.sm),
                  Expanded(child: Text(note, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          ],
          const SizedBox(height: NetSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: 0, label: Text('Cuerpo'), icon: Icon(Icons.data_object, size: 18)),
                ButtonSegment(
                  value: 1,
                  label: Text('Encabezados (${r.headers.length})'),
                  icon: const Icon(Icons.list_alt, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: NetSpacing.md),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: _tab == 0 ? _body() : _headers(),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final kind = switch (r.bodyKind) {
      BodyKind.json => 'Cuerpo (JSON)',
      BodyKind.text => 'Cuerpo (texto, no es JSON)',
      BodyKind.empty => 'Cuerpo vacío',
    };
    if (r.bodyKind == BodyKind.empty) {
      return Text(kind, style: NetText.muted(context));
    }
    final shown = r.displayBody;
    final truncated = shown.length > widget.maxChars;
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.45).clamp(180.0, 480.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kind, style: NetText.muted(context)),
        const SizedBox(height: NetSpacing.sm),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.all(NetSpacing.md),
          decoration: BoxDecoration(
            color: NetColors.background,
            borderRadius: BorderRadius.circular(NetRadius.md),
            border: Border.all(color: NetColors.border),
          ),
          child: SingleChildScrollView(
            child: SelectableText(truncated ? shown.substring(0, widget.maxChars) : shown, style: monoStyle),
          ),
        ),
        if (truncated)
          Padding(
            padding: const EdgeInsets.only(top: NetSpacing.sm),
            child: Text(
              'Respuesta truncada en pantalla; el botón Copiar copia el texto completo.',
              style: NetText.muted(context, size: 11.5),
            ),
          ),
      ],
    );
  }

  Widget _headers() {
    if (r.headers.isEmpty) {
      return Text('El servidor no devolvió encabezados relevantes.', style: NetText.muted(context));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetSpacing.md),
      decoration: BoxDecoration(
        color: NetColors.background,
        borderRadius: BorderRadius.circular(NetRadius.md),
        border: Border.all(color: NetColors.border),
      ),
      child: Column(children: [for (final e in r.headers.entries) KeyValueRow(e.key, e.value)]),
    );
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: r.displayBody));
    messenger.showSnackBar(const SnackBar(content: Text('Cuerpo copiado')));
  }

  Widget _failure() {
    final type = r.errorType ?? NetErrorType.unexpected;
    return PanelCard(
      title: 'Sin respuesta del servidor',
      icon: Icons.cloud_off,
      accent: NetColors.error,
      child: ErrorState(
        title: type.title,
        message: r.errorMessage ?? type.tip,
        tip: type.tip,
        footnote: 'Tras ${formatDuration(r.duration)}',
        onRetry: widget.retryEnabled ? widget.onRetry : null,
      ),
    );
  }
}
