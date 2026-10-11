import 'package:flutter_test/flutter_test.dart';
import 'package:netlab/core/utils/json_utils.dart';

void main() {
  group('JsonUtils.validate', () {
    test('acepta JSON válido', () {
      expect(JsonUtils.validate('{"a": 1}'), isNull);
      expect(JsonUtils.validate('[1, 2, 3]'), isNull);
    });
    test('rechaza JSON malformado', () {
      expect(JsonUtils.validate('{"a": '), contains('JSON inválido'));
    });
    test('rechaza texto vacío', () {
      expect(JsonUtils.validate('   '), isNotNull);
    });
  });

  group('JsonUtils.tryPretty', () {
    test('formatea JSON con sangría', () {
      expect(JsonUtils.tryPretty('{"a":1}'), '{\n  "a": 1\n}');
    });
    test('devuelve null si no es JSON o está vacío', () {
      expect(JsonUtils.tryPretty('<html></html>'), isNull);
      expect(JsonUtils.tryPretty(''), isNull);
    });
  });

  group('JsonUtils.parseHeaders', () {
    test('vacío => mapa vacío', () {
      expect(JsonUtils.parseHeaders(''), isEmpty);
    });
    test('objeto válido', () {
      expect(JsonUtils.parseHeaders('{"Accept": "application/json"}'),
          {'Accept': 'application/json'});
    });
    test('lanza FormatException si no es un objeto', () {
      expect(() => JsonUtils.parseHeaders('[1]'), throwsFormatException);
    });
    test('lanza FormatException si el JSON es inválido', () {
      expect(() => JsonUtils.parseHeaders('{x'), throwsFormatException);
    });
  });
}
