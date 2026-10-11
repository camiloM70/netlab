import 'api_result.dart';
import '../core/utils/http_status.dart';

/// Registro del historial: una solicitud o comprobación realmente ejecutada.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.client,
    required this.endpoint,
    required this.duration,
    required this.outcome,
    this.statusCode,
    this.message,
  });

  /// [kind] es el método (GET, POST...) o el tipo de prueba (DIAGNÓSTICO, DIO).
  factory HistoryEntry.fromResult(ApiResult r, {required int id, String? kind}) {
    final code = r.statusCode;
    return HistoryEntry(
      id: id,
      timestamp: r.timestamp,
      kind: kind ?? r.method,
      client: r.client,
      endpoint: r.url,
      duration: r.duration,
      outcome: r.outcome,
      statusCode: code,
      message: code == null ? r.errorMessage : (r.outcome == Outcome.success ? null : describeStatus(code)),
    );
  }

  final int id;
  final DateTime timestamp;
  final String kind;
  final String client;
  final String endpoint;
  final Duration duration;
  final Outcome outcome;
  final int? statusCode;
  final String? message;
}
