/// Explicación en español de un código de estado HTTP.
String describeStatus(int code) {
  switch (code) {
    case 200:
      return 'OK: la solicitud se procesó correctamente.';
    case 201:
      return 'Created: se creó un recurso.';
    case 204:
      return 'No Content: éxito sin cuerpo de respuesta.';
    case 400:
      return 'Bad Request: la solicitud está mal formada.';
    case 401:
      return 'Unauthorized: faltan credenciales válidas.';
    case 403:
      return 'Forbidden: no tienes permiso para este recurso.';
    case 404:
      return 'Not Found: el recurso no existe en el servidor.';
    case 500:
      return 'Internal Server Error: falló el servidor.';
  }
  if (code >= 200 && code < 300) return 'Éxito (2xx).';
  if (code >= 300 && code < 400) return 'Redirección (3xx).';
  if (code >= 400 && code < 500) return 'Error del cliente (4xx).';
  if (code >= 500 && code < 600) return 'Error del servidor (5xx).';
  return 'Código HTTP no estándar.';
}

/// Nota sobre persistencia para métodos de escritura exitosos.
/// Un 2xx prueba que el servidor aceptó la solicitud, no que guardó datos.
String? persistenceNote(String method, String url, int? status) {
  const writes = {'POST', 'PUT', 'PATCH', 'DELETE'};
  if (status == null || status < 200 || status >= 300) return null;
  if (!writes.contains(method.toUpperCase())) return null;
  if (url.toLowerCase().contains('jsonplaceholder')) {
    return 'HTTP exitoso, pero JSONPlaceholder solo SIMULA las escrituras: '
        'no guarda nada. Compruébalo con un GET posterior al recurso.';
  }
  return 'El servidor aceptó la solicitud (2xx). Eso no demuestra por sí solo '
      'que los datos se hayan guardado: verifica con un GET posterior.';
}
