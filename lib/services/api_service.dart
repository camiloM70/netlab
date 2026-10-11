import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/config/endpoints.dart';
import '../core/errors/net_error.dart';
import '../models/api_result.dart';

/// Devuelve la URI si es http(s) con host; si no, null.
Uri? parseHttpUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

/// Cliente REST sencillo basado en el paquete `http`.
/// Nunca lanza excepciones: siempre devuelve un [ApiResult].
class ApiService {
  ApiService({http.Client? client, this.timeout = Endpoints.requestTimeout})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _relevantHeaders = {
    'content-type',
    'content-length',
    'date',
    'server',
    'cache-control',
    'etag',
    'location',
    'access-control-allow-origin',
  };

  Future<ApiResult> send({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    String? body,
  }) async {
    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();
    final verb = method.toUpperCase();

    final uri = parseHttpUri(url);
    if (uri == null) {
      return ApiResult.failure(
        client: 'http',
        method: verb,
        url: url,
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        type: NetErrorType.invalidUrl,
        message: 'La URL no es válida. Debe empezar por http:// o https://.',
      );
    }

    try {
      final request = http.Request(verb, uri)..headers.addAll(headers);
      if (body != null && body.trim().isNotEmpty) {
        request.headers.putIfAbsent(
            'Content-Type', () => 'application/json; charset=utf-8');
        request.body = body;
      }
      // Tiempo de espera limitado: evita bloquear la operación indefinidamente.
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      stopwatch.stop();

      return ApiResult(
        client: 'http',
        method: verb,
        url: uri.toString(),
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        headers: {
          for (final e in response.headers.entries)
            if (_relevantHeaders.contains(e.key.toLowerCase())) e.key: e.value,
        },
        body: response.body,
      );
    } catch (e) {
      stopwatch.stop();
      final failure = classifyError(e);
      return ApiResult.failure(
        client: 'http',
        method: verb,
        url: uri.toString(),
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        type: failure.type,
        message: failure.message,
      );
    }
  }

  void close() => _client.close();
}
