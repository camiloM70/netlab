import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/history_entry.dart';
import '../models/api_result.dart';
import 'common.dart';
import 'visuals.dart';

/// Fila compacta para la actividad reciente.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final sev = outcomeSeverity(entry.outcome);
    final code = entry.statusCode?.toString() ?? 'ERR';
    return Semantics(
      label:
          '${entry.kind}, ${entry.outcome.label}, código $code, ${formatDuration(entry.duration)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(outcomeIcon(entry.outcome), size: 18, color: sev.color),
              const SizedBox(width: 10),
              SizedBox(
                width: 86,
                child: Text(entry.kind,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Expanded(
                child: Text(entry.endpoint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(code, style: TextStyle(color: sev.color, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              Text(formatDuration(entry.duration),
                  style: const TextStyle(color: NetColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Registro expandible con todos los detalles.
class HistoryDetailTile extends StatelessWidget {
  const HistoryDetailTile({super.key, required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final sev = outcomeSeverity(entry.outcome);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NetColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(outcomeIcon(entry.outcome), color: sev.color),
        title: Row(
          children: [
            Text(entry.kind, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text(entry.statusCode?.toString() ?? 'ERR',
                style: TextStyle(color: sev.color, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(formatDuration(entry.duration),
                style: const TextStyle(color: NetColors.textMuted, fontSize: 13)),
          ],
        ),
        subtitle: Text(
          '${formatTime(entry.timestamp)} · ${entry.endpoint}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: NetColors.textMuted, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          KeyValueRow('Fecha y hora', formatDateTime(entry.timestamp)),
          KeyValueRow('Tipo / método', entry.kind),
          KeyValueRow('Cliente', entry.client),
          KeyValueRow('Endpoint', entry.endpoint),
          KeyValueRow('Código HTTP', entry.statusCode?.toString() ?? 'Sin respuesta'),
          KeyValueRow('Duración', formatDuration(entry.duration)),
          KeyValueRow('Resultado', entry.outcome.label),
          if (entry.message != null) KeyValueRow('Detalle', entry.message!),
        ],
      ),
    );
  }
}
