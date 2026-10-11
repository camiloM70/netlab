import 'dart:convert';

/// Utilidades para validar y dar formato a JSON.
class JsonUtils {
  JsonUtils._();

  /// Devuelve `null` si [text] es JSON válido; si no, un mensaje en español.
  static String? validate(String text) {
    if (text.trim().isEmpty) return 'El JSON está vacío.';
    try {
      jsonDecode(text);
      return null;
    } on FormatException catch (e) {
      return 'JSON inválido: ${e.message}';
    }
  }

  /// JSON con sangría, o `null` si [text] no es JSON.
  static String? tryPretty(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  /// Interpreta el campo de encabezados: vacío => {}, o un objeto JSON plano.
  /// Lanza [FormatException] con un mensaje en español si es inválido.
  static Map<String, String> parseHeaders(String text) {
    if (text.trim().isEmpty) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException('Encabezados con JSON inválido: ${e.message}');
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Los encabezados deben ser un objeto JSON, por ejemplo {"Accept": "application/json"}.',
      );
    }
    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
