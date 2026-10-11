import 'dart:convert';

import '../core/errors/net_error.dart';
import '../core/utils/json_utils.dart';

/// Clasificación del resultado de una petición.
/// - success: respuesta HTTP 2xx.
/// - httpError: el servidor SÍ respondió, pero con código no 2xx (ej. 404, 500).
/// - failure: no hubo respuesta HTTP (red, DNS, timeout, URL inválida...).
enum Outcome { success, httpError, failure }

extension OutcomeText on Outcome {
  String get label => switch (this) {
        Outcome.success => 'Exitosa',
        Outcome.httpError => 'Error HTTP',
        Outcome.failure => 'Sin respuesta',
      };
}

enum BodyKind { empty, json, text }

/// Resultado de una petición HTTP real (hecha con `http` o con `dio`).
class ApiResult {
  const ApiResult({
    required this.client,
    required this.method,
    required this.url,
    required this.timestamp,
    required this.duration,
    this.statusCode,
    this.reasonPhrase,
    this.headers = const {},
    this.body = '',
    this.errorType,
    this.errorMessage,
  });

  factory ApiResult.failure({
    required String client,
    required String method,
    required String url,
    required DateTime timestamp,
    required Duration duration,
    required NetErrorType type,
    required String message,
  }) =>
      ApiResult(
        client: client,
        method: method,
        url: url,
        timestamp: timestamp,
        duration: duration,
        errorType: type,
        errorMessage: message,
      );

  final String client; // 'http' | 'dio'
  final String method;
  final String url;
  final DateTime timestamp;
  final Duration duration;
  final int? statusCode;
  final String? reasonPhrase;
  final Map<String, String> headers;
  final String body;
  final NetErrorType? errorType;
  final String? errorMessage;

  bool get hasResponse => statusCode != null;

  Outcome get outcome {
    final code = statusCode;
    if (code == null) return Outcome.failure;
    return code >= 200 && code < 300 ? Outcome.success : Outcome.httpError;
  }

  int get sizeBytes => utf8.encode(body).length;

  BodyKind get bodyKind {
    if (body.trim().isEmpty) return BodyKind.empty;
    return JsonUtils.tryPretty(body) != null ? BodyKind.json : BodyKind.text;
  }

  /// Cuerpo listo para mostrar: JSON con sangría o texto tal cual.
  String get displayBody => JsonUtils.tryPretty(body) ?? body;

  ApiResult copyWith({NetErrorType? errorType, String? errorMessage}) =>
      ApiResult(
        client: client,
        method: method,
        url: url,
        timestamp: timestamp,
        duration: duration,
        statusCode: statusCode,
        reasonPhrase: reasonPhrase,
        headers: headers,
        body: body,
        errorType: errorType ?? this.errorType,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  /// Si la petición no obtuvo respuesta y el sistema reporta que no hay red,
  /// el motivo más útil para el usuario es "Sin conexión".
  ApiResult withOfflineHint(bool deviceOffline) {
    if (!deviceOffline || hasResponse) return this;
    const transport = {
      NetErrorType.connection,
      NetErrorType.dns,
      NetErrorType.timeout,
    };
    if (!transport.contains(errorType)) return this;
    return copyWith(
      errorType: NetErrorType.noConnection,
      errorMessage:
          'El sistema no reporta ninguna red activa, por lo que la solicitud no pudo completarse.',
    );
  }
}
