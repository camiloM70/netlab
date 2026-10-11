import 'package:flutter_test/flutter_test.dart';
import 'package:netlab/core/errors/net_error.dart';
import 'package:netlab/models/api_result.dart';
import 'package:netlab/services/history_service.dart';

ApiResult ok(String method) => ApiResult(
      client: 'http',
      method: method,
      url: 'https://example.com/$method',
      timestamp: DateTime(2026, 1, 1, 10),
      duration: const Duration(milliseconds: 120),
      statusCode: 200,
    );

ApiResult notFound() => ApiResult(
      client: 'http',
      method: 'GET',
      url: 'https://example.com/404',
      timestamp: DateTime(2026),
      duration: const Duration(milliseconds: 80),
      statusCode: 404,
    );

ApiResult failed() => ApiResult.failure(
      client: 'http',
      method: 'GET',
      url: 'https://example.com',
      timestamp: DateTime(2026),
      duration: const Duration(seconds: 10),
      type: NetErrorType.timeout,
      message: 'Se agotó el tiempo',
    );

void main() {
  test('registra con el más reciente primero', () {
    final h = HistoryService();
    h.add(ok('GET'));
    h.add(ok('POST'));
    expect(h.entries.first.kind, 'POST');
    expect(h.entries.length, 2);
  });

  test('interpreta resultados: éxito, error HTTP y sin respuesta', () {
    final h = HistoryService();
    final a = h.add(ok('GET'));
    final b = h.add(notFound());
    final c = h.add(failed(), kind: 'DIAGNÓSTICO');
    expect(a.outcome, Outcome.success);
    expect(a.message, isNull);
    expect(b.outcome, Outcome.httpError);
    expect(b.statusCode, 404);
    expect(b.message, contains('Not Found'));
    expect(c.outcome, Outcome.failure);
    expect(c.statusCode, isNull);
    expect(c.kind, 'DIAGNÓSTICO');
    expect(c.message, 'Se agotó el tiempo');
  });

  test('respeta el máximo de registros', () {
    final h = HistoryService(maxEntries: 3);
    for (var i = 0; i < 5; i++) {
      h.add(ok('GET'));
    }
    expect(h.entries.length, 3);
  });

  test('filtra por tipo y resultado', () {
    final h = HistoryService();
    h.add(ok('GET'));
    h.add(ok('POST'));
    h.add(notFound());
    expect(HistoryService.apply(h.entries, kind: 'POST').length, 1);
    expect(HistoryService.apply(h.entries, outcome: Outcome.httpError).length, 1);
    expect(HistoryService.apply(h.entries, kind: 'GET', outcome: Outcome.success).length, 1);
    expect(HistoryService.apply(h.entries).length, 3);
  });

  test('clear vacía el historial', () {
    final h = HistoryService()..add(ok('GET'));
    h.clear();
    expect(h.entries, isEmpty);
  });
}
