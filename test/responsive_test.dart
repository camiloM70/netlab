import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:netlab/app.dart';
import 'package:netlab/widgets/activity_widgets.dart';

import 'test_helpers.dart';

void expectNoFlutterException(
  WidgetTester tester, {
  required String stage,
  required double width,
}) {
  final exception = tester.takeException();
  if (exception == null) return;

  final details = exception is FlutterError
      ? exception.diagnostics.map((node) => node.toStringDeep()).join('\n')
      : exception.toString();
  fail('$stage at ${width.toInt()} dp:\n$details');
}

/// Recorre las 4 secciones y envía una solicitud en cada ancho de referencia.
/// Un RenderFlex overflow u otro error de layout aparece como excepción capturada.
void main() {
  const widths = <double>[320, 360, 390, 430, 600, 768, 1024];

  for (final w in widths) {
    testWidgets('sin errores de layout con ancho ${w.toInt()} dp', (tester) async {
      useSize(tester, Size(w, 800));
      final c = buildController(
        connectivity: [ConnectivityResult.wifi, ConnectivityResult.vpn],
        handler: (_) async => http.Response(
          '{"id":1,"title":"Un título bastante largo para comprobar el ajuste de texto"}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.pumpWidget(NetLabApp(key: ValueKey(w), controller: c));
      await tester.pumpAndSettle();
      expectNoFlutterException(tester, stage: 'Inicio', width: w);

      // API REST: enviar una solicitud y ver la respuesta.
      await tester.tap(find.byIcon(Icons.http_outlined));
      await tester.pumpAndSettle();
      final send = find.text('Enviar');
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      expect(
        send.hitTestable(),
        findsOneWidget,
        reason: 'Enviar debe estar visible y ser pulsable a ${w.toInt()} dp',
      );
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('Respuesta'), findsWidgets);
      expectNoFlutterException(tester, stage: 'API REST', width: w);

      // Diagnóstico.
      await tester.tap(find.byIcon(Icons.network_check_outlined));
      await tester.pumpAndSettle();
      expectNoFlutterException(tester, stage: 'Diagnóstico', width: w);

      // Historial con registros.
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryDetailTile), findsWidgets);
      expectNoFlutterException(tester, stage: 'Historial', width: w);
    });
  }
}
