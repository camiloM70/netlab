import 'dart:async';
import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart' as http;

/// Categorías de fallo de TRANSPORTE (la petición no obtuvo respuesta HTTP).
/// Un HTTP 404 o 500 NO está aquí: es una respuesta válida del servidor.
enum NetErrorType {
  noConnection,
  dns,
  connection,
  timeout,
  invalidUrl,
  cancelled,
  unexpected,
}

extension NetErrorTypeText on NetErrorType {
  String get title => switch (this) {
        NetErrorType.noConnection => 'Sin conexión',
        NetErrorType.dns => 'Error DNS',
        NetErrorType.connection => 'Servidor inaccesible',
        NetErrorType.timeout => 'Tiempo de espera agotado',
        NetErrorType.invalidUrl => 'URL inválida',
        NetErrorType.cancelled => 'Solicitud cancelada',
        NetErrorType.unexpected => 'Error inesperado',
      };

  String get tip => switch (this) {
        NetErrorType.noConnection =>
          'Activa Wi-Fi o datos móviles y vuelve a intentarlo.',
        NetErrorType.dns =>
          'El nombre del servidor no se pudo resolver. Revisa la URL o la red.',
        NetErrorType.connection =>
          'No se pudo establecer la conexión. El servidor puede estar caído o bloqueado.',
        NetErrorType.timeout =>
          'El servidor tardó demasiado. Reintenta o prueba otra red.',
        NetErrorType.invalidUrl =>
          'Usa una URL completa que empiece por http:// o https://.',
        NetErrorType.cancelled =>
          'La respuesta, si llega, se ignorará en pantalla.',
        NetErrorType.unexpected => 'Ocurrió un error no previsto.',
      };
}

class NetFailure {
  const NetFailure(this.type, this.message);
  final NetErrorType type;
  final String message;
}

/// Traduce una excepción de `http` / `dart:io` / `dart:async` a un [NetFailure].
NetFailure classifyError(Object error) {
  if (error is TimeoutException) {
    return const NetFailure(
      NetErrorType.timeout,
      'El servidor no respondió dentro del tiempo límite.',
    );
  }
  final text = error.toString().toLowerCase();
  if (_looksLikeDns(text)) {
    return const NetFailure(
      NetErrorType.dns,
      'No se pudo resolver el nombre del servidor (DNS).',
    );
  }
  if (error is SocketException ||
      error is HandshakeException ||
      error is http.ClientException) {
    if (text.contains('xmlhttprequest') || text.contains('failed to fetch')) {
      return const NetFailure(
        NetErrorType.connection,
        'El navegador no pudo completar la solicitud. En Web puede deberse a '
        'CORS o a falta de red.',
      );
    }
    return const NetFailure(
      NetErrorType.connection,
      'No se pudo conectar con el servidor.',
    );
  }
  return NetFailure(NetErrorType.unexpected, error.toString());
}

bool _looksLikeDns(String t) =>
    t.contains('failed host lookup') ||
    t.contains('no address associated') ||
    t.contains('nodename nor servname') ||
    t.contains('name or service not known') ||
    t.contains('err_name_not_resolved');
