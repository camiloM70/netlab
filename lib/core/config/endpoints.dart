/// Configuración de endpoints de demostración.
///
/// JSONPlaceholder acepta POST/PUT/DELETE y responde con códigos de éxito,
/// pero NO persiste los cambios (es una API de pruebas). Para demostrar
/// persistencia real usa el backend local de `backend_local/` (json-server).
class Endpoints {
  Endpoints._();

  static const String base = 'https://jsonplaceholder.typicode.com';

  /// Recurso pequeño usado para comprobar si el servidor es accesible.
  static const String healthCheck = '$base/todos/1';

  /// Tiempo máximo de espera de las solicitudes del explorador y diagnóstico.
  static const Duration requestTimeout = Duration(seconds: 10);

  static const List<RequestExample> examples = [
    RequestExample(
      title: 'GET lista',
      method: 'GET',
      url: '$base/posts?_limit=5',
      description: 'Consulta una lista de recursos (5 publicaciones).',
    ),
    RequestExample(
      title: 'GET recurso',
      method: 'GET',
      url: '$base/posts/1',
      description: 'Consulta un recurso individual.',
    ),
    RequestExample(
      title: 'POST crear',
      method: 'POST',
      url: '$base/posts',
      headers: '{"Accept": "application/json"}',
      body:
          '{\n  "title": "NetLab",\n  "body": "Prueba desde Flutter",\n  "userId": 1\n}',
      description: 'Envía un objeto JSON. Responde 201 con un id simulado.',
    ),
    RequestExample(
      title: 'PUT actualizar',
      method: 'PUT',
      url: '$base/posts/1',
      headers: '{"Accept": "application/json"}',
      body:
          '{\n  "id": 1,\n  "title": "Título actualizado",\n  "body": "Cuerpo actualizado",\n  "userId": 1\n}',
      description: 'Envía una actualización de prueba. Responde 200.',
    ),
    RequestExample(
      title: 'DELETE eliminar',
      method: 'DELETE',
      url: '$base/posts/1',
      description: 'Solicitud de eliminación de prueba (pide confirmación).',
    ),
    RequestExample(
      title: 'GET 404',
      method: 'GET',
      url: '$base/posts/99999',
      description:
          'Recurso inexistente: HTTP 404 válido, no es un fallo de red.',
    ),
    RequestExample(
      title: '¿Persistió el POST?',
      method: 'GET',
      url: '$base/posts/101',
      description:
          'Tras un POST a /posts, JSONPlaceholder devuelve id 101, pero este GET da 404: no se guardó.',
    ),
  ];
}

class RequestExample {
  const RequestExample({
    required this.title,
    required this.method,
    required this.url,
    required this.description,
    this.headers,
    this.body,
  });

  final String title;
  final String method;
  final String url;
  final String description;
  final String? headers;
  final String? body;
}
