import 'package:dio/dio.dart';

import '../core/config/endpoints.dart';
import '../core/errors/net_error.dart';
import '../models/api_result.dart';
import 'api_service.dart';

/// Escenarios del panel de depuración avanzada (todos son peticiones reales).
enum DioScenario {
  ok(
    'GET 200',
    Endpoints.healthCheck,
    Duration(seconds: 8),
    'Respuesta correcta: el interceptor registra método, URL, código y duración.',
  ),
  notFound(
    'GET 404',
    '${Endpoints.base}/posts/99999',
    Duration(seconds: 8),
    'El servidor responde 404. Con validateStatus permisivo Dio NO lo lanza como excepción.',
  ),
  forcedTimeout(
    'Timeout forzado',
    Endpoints.healthCheck,
    Duration(milliseconds: 1),
    'Tiempo de conexión de 1 ms: casi siempre se agota antes de conectar.',
  ),
  unknownHost(
    'Host inexistente',
    'https://servidor-inexistente.netlab.invalid/',
    Duration(seconds: 8),
    'El dominio .invalid nunca resuelve: produce un error DNS/conexión.',
  );

  const DioScenario(this.label, this.url, this.connectTimeout, this.description);
  final String label;
  final String url;
  final Duration connectTimeout;
  final String description;
}

/// Cliente avanzado con `dio`. Se usa para depuración: interceptor con trazas,
/// tiempos de espera explícitos y clasificación de errores.
class DioApiService {
  DioApiService({Dio? dio, this.onLog}) : _dio = dio ?? Dio() {
    _dio.interceptors.add(_DebugInterceptor(_log));
  }

  final Dio _dio;

  /// Recibe cada línea de traza del interceptor.
  final void Function(String line)? onLog;

  void _log(String line) => onLog?.call(line);

  Future<ApiResult> request({
    required String url,
    String method = 'GET',
    Duration connectTimeout = const Duration(seconds: 8),
    Duration receiveTimeout = const Duration(seconds: 8),
  }) async {
    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();
    final verb = method.toUpperCase();

    final uri = parseHttpUri(url);
    if (uri == null) {
      return ApiResult.failure(
        client: 'dio',
        method: verb,
        url: url,
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        type: NetErrorType.invalidUrl,
        message: 'La URL no es válida. Debe empezar por http:// o https://.',
      );
    }

    try {
      final response = await _dio.fetch<String>(RequestOptions(
        path: uri.toString(),
        method: verb,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.plain,
        // Aceptamos cualquier código: un 404 es una respuesta válida, no un fallo.
        validateStatus: (_) => true,
      ));
      stopwatch.stop();
      return ApiResult(
        client: 'dio',
        method: verb,
        url: uri.toString(),
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        statusCode: response.statusCode,
        reasonPhrase: response.statusMessage,
        headers: {
          for (final e in response.headers.map.entries)
            if (const {'content-type', 'content-length', 'date', 'server'}
                .contains(e.key.toLowerCase()))
              e.key: e.value.join(', '),
        },
        body: response.data ?? '',
      );
    } on DioException catch (e) {
      stopwatch.stop();
      final failure = _classifyDio(e);
      return ApiResult.failure(
        client: 'dio',
        method: verb,
        url: uri.toString(),
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        type: failure.type,
        message: failure.message,
      );
    } catch (e) {
      stopwatch.stop();
      final failure = classifyError(e);
      return ApiResult.failure(
        client: 'dio',
        method: verb,
        url: uri.toString(),
        timestamp: timestamp,
        duration: stopwatch.elapsed,
        type: failure.type,
        message: failure.message,
      );
    }
  }

  NetFailure _classifyDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetFailure(
          NetErrorType.timeout,
          'Dio agotó el tiempo de espera (conexión, envío o recepción).',
        );
      case DioExceptionType.cancel:
        return const NetFailure(
            NetErrorType.cancelled, 'La solicitud fue cancelada.');
      case DioExceptionType.badCertificate:
        return const NetFailure(
          NetErrorType.connection,
          'El certificado TLS del servidor no es de confianza.',
        );
      default:
        final inner = classifyError(e.error ?? e);
        // Dio ya sabe que no hubo respuesta: no lo dejamos como "inesperado"
        // si el motivo es de transporte.
        if (inner.type == NetErrorType.unexpected &&
            e.type == DioExceptionType.connectionError) {
          return const NetFailure(
              NetErrorType.connection, 'No se pudo conectar con el servidor.');
        }
        return inner;
    }
  }

  void close() => _dio.close();
}

/// Interceptor de depuración. Registra solo método, URL SIN query, código y
/// duración. No registra encabezados ni cuerpos (podrían contener secretos).
class _DebugInterceptor extends Interceptor {
  _DebugInterceptor(this._log);
  final void Function(String) _log;

  static const _key = 'netlab_stopwatch';

  String _safe(Uri u) => '${u.scheme}://${u.host}${u.path}';

  int _elapsed(RequestOptions o) {
    final sw = o.extra[_key];
    return sw is Stopwatch ? sw.elapsedMilliseconds : -1;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_key] = Stopwatch()..start();
    _log('→ ${options.method} ${_safe(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    _log('← ${response.statusCode} en ${_elapsed(o)} ms  ${_safe(o.uri)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    _log('✕ ${err.type.name} tras ${_elapsed(o)} ms  ${_safe(o.uri)}');
    handler.next(err);
  }
}
