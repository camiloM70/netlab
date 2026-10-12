import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/api_result.dart';
import '../models/history_entry.dart';
import 'common.dart';
import 'visuals.dart';

/// Fila compacta (2 líneas) para la actividad reciente. Las URLs largas se recortan.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final sev = outcomeSeverity(entry.outcome);
    final code = entry.statusCode?.toString() ?? 'ERR';
    return Semantics(
      label: '${entry.kind}, ${entry.outcome.label}, código $code, ${formatDuration(entry.duration)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: NetSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(outcomeIcon(entry.outcome), size: 18, color: sev.color),
                  const SizedBox(width: NetSpacing.sm),
                  Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: MethodBadge(entry.kind))),
                  const SizedBox(width: NetSpacing.sm),
                  Text(code, style: TextStyle(color: sev.color, fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text(formatDuration(entry.duration), style: NetText.muted(context, size: 12)),
                  const SizedBox(width: NetSpacing.sm),
                  Text(formatTime(entry.timestamp), style: NetText.muted(context, size: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(entry.endpoint,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: NetText.muted(context, size: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de columnas para la vista ancha del historial.
class HistoryTableHeader extends StatelessWidget {
  const HistoryTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = NetText.muted(context, size: 12).copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(NetSpacing.lg, 0, NetSpacing.lg + 40, NetSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text('Tipo', style: s)),
          SizedBox(width: 90, child: Text('Estado', style: s)),
          Expanded(child: Text('Endpoint', style: s)),
          SizedBox(width: 90, child: Text('Duración', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('Hora', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

/// Registro expandible. [wide] = columnas alineadas; si no, tarjeta compacta.
class HistoryDetailTile extends StatelessWidget {
  const HistoryDetailTile({super.key, required this.entry, this.wide = false});
  final HistoryEntry entry;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final sev = outcomeSeverity(entry.outcome);
    final code = entry.statusCode?.toString() ?? 'ERR';
    final Widget title;
    final Widget? subtitle;
    if (wide) {
      title = Row(
        children: [
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: MethodBadge(entry.kind)),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                Icon(outcomeIcon(entry.outcome), size: 16, color: sev.color),
                const SizedBox(width: 6),
                Text(code, style: TextStyle(color: sev.color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(child: Text(entry.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 90,
            child: Text(formatDuration(entry.duration), textAlign: TextAlign.right, style: NetText.muted(context, size: 13)),
          ),
          SizedBox(
            width: 90,
            child: Text(formatTime(entry.timestamp), textAlign: TextAlign.right, style: NetText.muted(context, size: 13)),
          ),
        ],
      );
      subtitle = null;
    } else {
      title = Row(
        children: [
          Icon(outcomeIcon(entry.outcome), size: 18, color: sev.color),
          const SizedBox(width: NetSpacing.sm),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: MethodBadge(entry.kind))),
          const SizedBox(width: NetSpacing.sm),
          Text(code, style: TextStyle(color: sev.color, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(formatDuration(entry.duration), style: NetText.muted(context, size: 13)),
        ],
      );
      subtitle = Padding(
        padding: const EdgeInsets.only(top: NetSpacing.xs),
        child: Text(
          '${formatTime(entry.timestamp)} · ${entry.endpoint}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: NetText.muted(context, size: 12),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: NetSpacing.sm),
      decoration: BoxDecoration(
        color: NetColors.surface,
        borderRadius: BorderRadius.circular(NetRadius.md),
        border: Border.all(color: NetColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NetRadius.md - 1),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: NetSpacing.lg, vertical: 2),
          title: title,
          subtitle: subtitle,
          childrenPadding: const EdgeInsets.fromLTRB(NetSpacing.lg, 0, NetSpacing.lg, NetSpacing.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}
