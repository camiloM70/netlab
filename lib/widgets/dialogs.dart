import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Diálogo de confirmación con estilo uniforme. `scrollable: true` evita
/// desbordes en pantallas pequeñas o con el teclado abierto.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      backgroundColor: NetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NetRadius.lg),
        side: const BorderSide(color: NetColors.border),
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}
