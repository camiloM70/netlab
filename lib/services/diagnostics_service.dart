import '../core/config/endpoints.dart';
import '../core/utils/format.dart';
import '../core/utils/http_status.dart';
import '../models/api_result.dart';
import '../core/errors/net_error.dart';
import '../models/severity.dart';
import 'api_service.dart';

enum VerdictKind {
  reachable,
  httpError,
  noConnection,
  timeout,
  unreachable,
  invalidUrl,
  unexpected,
}

/// Interpretación en lenguaje claro de un resultado de diagnóstico.
class Verdict {
  const Verdict(this.kind, this.title, this.detail, this.severity);
  final VerdictKind kind;
  final String title;
  final String detail;
  final Severity severity;
}

/// Clasifica un [ApiResult] como veredicto del servidor de pruebas.
Verdict classifyResult(ApiResult r) {
  final code = r.statusCode;
  if (code != null) {
    if (r.outcome == Outcome.success) {
      return Verdict(
        VerdictKind.reachable,
        'Servidor accesible',
        'Respondió HTTP $code en ${formatDuration(r.duration)}.',
        Severity.ok,
      );
    }
    return Verdict(
      VerdictKind.httpError,
      'El servidor respondió con error HTTP',
      'El servidor es accesible y respondió $code. ${describeStatus(code)}',
      Severity.warn,
    );
  }
  final message = r.errorMessage ?? '';
  switch (r.errorType) {
    case NetErrorType.noConnection:
      return Verdict(VerdictKind.noConnection, 'Sin conexión', message, Severity.error);
    case NetErrorType.timeout:
      return Verdict(VerdictKind.timeout, 'Tiempo de espera agotado', message, Severity.error);
    case NetErrorType.dns:
    case NetErrorType.connection:
      return Verdict(VerdictKind.unreachable, 'Servidor inaccesible', message, Severity.error);
    case NetErrorType.invalidUrl:
      return Verdict(VerdictKind.invalidUrl, 'URL inválida', message, Severity.error);
    case NetErrorType.cancelled:
    case NetErrorType.unexpected:
    case null:
      return Verdict(VerdictKind.unexpected, 'Error inesperado', message, Severity.error);
  }
}

enum LatencyClass { fast, acceptable, slow }

extension LatencyText on LatencyClass {
  String get label => switch (this) {
        LatencyClass.fast => 'Rápida',
        LatencyClass.acceptable => 'Aceptable',
        LatencyClass.slow => 'Lenta',
      };
}

/// Clasifica el tiempo de respuesta HTTP (no es un ping ICMP).
LatencyClass classifyLatency(Duration d) {
  final ms = d.inMilliseconds;
  if (ms < 300) return LatencyClass.fast;
  if (ms < 1000) return LatencyClass.acceptable;
  return LatencyClass.slow;
}

/// Resultado completo de una comprobación del servidor.
class ServerCheck {
  const ServerCheck(this.result, this.verdict);
  final ApiResult result;
  final Verdict verdict;
  LatencyClass? get latency =>
      result.hasResponse ? classifyLatency(result.duration) : null;
}

/// Comprueba si un servidor es accesible con una petición HTTP REAL.
class DiagnosticsService {
  DiagnosticsService(this._api);
  final ApiService _api;

  Future<ApiResult> probe([String url = Endpoints.healthCheck]) =>
      _api.send(method: 'GET', url: url);
}
