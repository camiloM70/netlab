import 'package:flutter_test/flutter_test.dart';
import 'package:netlab/core/errors/net_error.dart';
import 'package:netlab/core/utils/http_status.dart';
import 'package:netlab/models/api_result.dart';
import 'package:netlab/models/severity.dart';
import 'package:netlab/services/diagnostics_service.dart';

ApiResult withStatus(int code) => ApiResult(
      client: 'http',
      method: 'GET',
      url: 'https://example.com',
      timestamp: DateTime(2026),
      duration: const Duration(milliseconds: 150),
      statusCode: code,
    );

ApiResult withError(NetErrorType t) => ApiResult.failure(
      client: 'http',
      method: 'GET',
      url: 'https://example.com',
      timestamp: DateTime(2026),
      duration: const Duration(milliseconds: 150),
      type: t,
      message: 'detalle',
    );

void main() {
  group('classifyResult', () {
    test('2xx => servidor accesible', () {
      final v = classifyResult(withStatus(200));
      expect(v.kind, VerdictKind.reachable);
      expect(v.severity, Severity.ok);
    });
    test('4xx/5xx => el servidor respondió con error HTTP (no es fallo de red)', () {
      expect(classifyResult(withStatus(404)).kind, VerdictKind.httpError);
      expect(classifyResult(withStatus(500)).kind, VerdictKind.httpError);
      expect(classifyResult(withStatus(404)).severity, Severity.warn);
    });
    test('errores de transporte', () {
      expect(classifyResult(withError(NetErrorType.noConnection)).kind, VerdictKind.noConnection);
      expect(classifyResult(withError(NetErrorType.timeout)).kind, VerdictKind.timeout);
      expect(classifyResult(withError(NetErrorType.dns)).kind, VerdictKind.unreachable);
      expect(classifyResult(withError(NetErrorType.connection)).kind, VerdictKind.unreachable);
      expect(classifyResult(withError(NetErrorType.invalidUrl)).kind, VerdictKind.invalidUrl);
      expect(classifyResult(withError(NetErrorType.unexpected)).kind, VerdictKind.unexpected);
    });
  });

  group('classifyLatency', () {
    test('umbrales', () {
      expect(classifyLatency(const Duration(milliseconds: 120)), LatencyClass.fast);
      expect(classifyLatency(const Duration(milliseconds: 300)), LatencyClass.acceptable);
      expect(classifyLatency(const Duration(milliseconds: 999)), LatencyClass.acceptable);
      expect(classifyLatency(const Duration(seconds: 2)), LatencyClass.slow);
    });
  });

  group('http_status', () {
    test('describeStatus', () {
      expect(describeStatus(404), contains('Not Found'));
      expect(describeStatus(201), contains('Created'));
      expect(describeStatus(418), contains('4xx'));
    });
    test('persistenceNote solo para escrituras exitosas', () {
      expect(persistenceNote('GET', 'https://x.com', 200), isNull);
      expect(persistenceNote('POST', 'https://x.com', 500), isNull);
      expect(persistenceNote('POST', 'https://x.com', null), isNull);
      expect(persistenceNote('POST', 'https://jsonplaceholder.typicode.com/posts', 201),
          contains('SIMULA'));
      expect(persistenceNote('PUT', 'https://otra.api/x', 200), contains('GET posterior'));
    });
  });
}
