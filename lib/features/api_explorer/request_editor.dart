import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import 'http_method_selector.dart';

/// Formulario de solicitud. Es "tonto": el estado vive en la pantalla.
class RequestEditor extends StatelessWidget {
  const RequestEditor({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.urlController,
    required this.headersController,
    required this.bodyController,
    required this.hasBody,
    required this.loading,
    required this.onSend,
    required this.onCancel,
    required this.onFormatBody,
    required this.onClearBody,
    this.inputError,
    this.notice,
  });

  final String method;
  final ValueChanged<String> onMethodChanged;
  final TextEditingController urlController;
  final TextEditingController headersController;
  final TextEditingController bodyController;
  final bool hasBody;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onFormatBody;
  final VoidCallback onClearBody;
  final String? inputError;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Solicitud',
      icon: Icons.send_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HttpMethodSelector(selected: method, onChanged: onMethodChanged),
          const SizedBox(height: NetSpacing.lg),
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: 3, // endpoints largos se ven completos
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: netInput('URL del endpoint', hint: 'https://…'),
          ),
          const SizedBox(height: NetSpacing.lg),
          TextField(
            controller: headersController,
            minLines: 2,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            style: monoStyle,
            decoration: netInput('Encabezados (JSON, opcional)', hint: '{"Accept": "application/json"}'),
          ),
          const SizedBox(height: NetSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasBody ? 'Cuerpo JSON' : 'Cuerpo JSON (solo POST, PUT y PATCH)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Formatear JSON',
                onPressed: hasBody ? onFormatBody : null,
                icon: const Icon(Icons.auto_fix_high),
              ),
              IconButton(
                tooltip: 'Limpiar cuerpo',
                onPressed: hasBody ? onClearBody : null,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
          const SizedBox(height: NetSpacing.xs),
          TextField(
            controller: bodyController,
            enabled: hasBody,
            minLines: 4,
            maxLines: 8,
            autocorrect: false,
            enableSuggestions: false,
            style: monoStyle,
            decoration: netInput('Cuerpo', hint: hasBody ? '{"clave": "valor"}' : 'No aplica para $method'),
          ),
          if (inputError != null) ...[
            const SizedBox(height: NetSpacing.md),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 18, color: NetColors.error),
                  const SizedBox(width: NetSpacing.sm),
                  Expanded(
                    child: Text(inputError!, style: const TextStyle(color: NetColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          if (notice != null) ...[
            const SizedBox(height: NetSpacing.md),
            Text(notice!, style: NetText.muted(context)),
          ],
          const SizedBox(height: NetSpacing.lg),
          Wrap(
            spacing: NetSpacing.md,
            runSpacing: NetSpacing.sm,
            children: [
              PrimaryButton(
                label: 'Enviar',
                loadingLabel: 'Enviando…',
                icon: Icons.play_arrow,
                loading: loading,
                onPressed: onSend,
              ),
              if (loading) OutlinedButton(onPressed: onCancel, child: const Text('Cancelar')),
            ],
          ),
        ],
      ),
    );
  }
}
