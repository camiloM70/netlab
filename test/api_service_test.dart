import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netlab/core/errors/net_error.dart';
import 'package:netlab/models/api_result.dart';
import 'package:netlab/services/api_service.dart';

ApiService serviceWith(MockClientHandler handler,
        {Duration timeout = const Duration(seconds: 2)}) =>
    ApiService(client: MockClient(handler), timeout: timeout);

void main() {
  test('200 con JSON => success, cuerpo JSON y encabezados relevantes', () async {
    final api = serviceWith((_) async => http.Response('{"id":1}', 200,
        headers: {'content-type': 'application/json', 'x-secret': 'no'}));
    final r = await api.send(method: 'GET', url: 'https://example.com/a');
    expect(r.statusCode, 200);
    expect(r.outcome, Outcome.success);
    expect(r.bodyKind, BodyKind.json);
    expect(r.headers.keys, contains('content-type'));
    expect(r.headers.keys, isNot(contains('x-secret')));
  });

  test('404 es una respuesta HTTP válida, no un fallo de transporte', () async {
    final api = serviceWith((_) async => http.Response('{}', 404));
    final r = await api.send(method: 'GET', url: 'https://example.com/x');
    expect(r.hasResponse, isTrue);
    expect(r.outcome, Outcome.httpError);
    expect(r.errorType, isNull);
  });

  test('500 => httpError', () async {
    final api = serviceWith((_) async => http.Response('boom', 500));
    final r = await api.send(method: 'GET', url: 'https://example.com/x');
    expect(r.outcome, Outcome.httpError);
    expect(r.bodyKind, BodyKind.text);
  });

  test('respuesta vacía => BodyKind.empty', () async {
    final api = serviceWith((_) async => http.Response('', 204));
    final r = await api.send(method: 'DELETE', url: 'https://example.com/x');
    expect(r.outcome, Outcome.success);
    expect(r.bodyKind, BodyKind.empty);
  });

  test('POST envía el cuerpo y Content-Type JSON', () async {
    late http.Request captured;
    final api = serviceWith((req) async {
      captured = req;
      return http.Response('{"id":101}', 201);
    });
    final r = await api.send(
        method: 'POST', url: 'https://example.com/posts', body: '{"a":1}');
    expect(r.statusCode, 201);
    expect(captured.method, 'POST');
    expect(captured.body, '{"a":1}');
    expect(captured.headers['Content-Type'], contains('application/json'));
  });

  test('URL inválida => invalidUrl sin tocar la red', () async {
    var called = false;
    final api = serviceWith((_) async {
      called = true;
      return http.Response('', 200);
    });
    final r = await api.send(method: 'GET', url: 'esto no es url');
    expect(r.errorType, NetErrorType.invalidUrl);
    expect(called, isFalse);
  });

  test('esquema no http(s) => invalidUrl', () async {
    final api = serviceWith((_) async => http.Response('', 200));
    final r = await api.send(method: 'GET', url: 'ftp://example.com/a');
    expect(r.errorType, NetErrorType.invalidUrl);
  });

  test('SocketException => connection', () async {
    final api = serviceWith((_) async => throw const SocketException('Connection refused'));
    final r = await api.send(method: 'GET', url: 'https://example.com');
    expect(r.errorType, NetErrorType.connection);
    expect(r.outcome, Outcome.failure);
  });

  test('fallo de resolución de nombre => dns', () async {
    final api = serviceWith((_) async =>
        throw const SocketException("Failed host lookup: 'x.invalid'"));
    final r = await api.send(method: 'GET', url: 'https://x.invalid');
    expect(r.errorType, NetErrorType.dns);
  });

  test('tiempo de espera agotado => timeout', () async {
    final api = serviceWith((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return http.Response('{}', 200);
    }, timeout: const Duration(milliseconds: 40));
    final r = await api.send(method: 'GET', url: 'https://example.com');
    expect(r.errorType, NetErrorType.timeout);
  });

  test('error desconocido => unexpected', () async {
    final api = serviceWith((_) async => throw StateError('algo raro'));
    final r = await api.send(method: 'GET', url: 'https://example.com');
    expect(r.errorType, NetErrorType.unexpected);
  });

  test('withOfflineHint convierte fallos de transporte en "sin conexión"', () {
    final base = ApiResult.failure(
      client: 'http',
      method: 'GET',
      url: 'https://example.com',
      timestamp: DateTime(2026),
      duration: Duration.zero,
      type: NetErrorType.connection,
      message: 'x',
    );
    expect(base.withOfflineHint(true).errorType, NetErrorType.noConnection);
    expect(base.withOfflineHint(false).errorType, NetErrorType.connection);
  });
}
