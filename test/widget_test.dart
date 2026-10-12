import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:netlab/app.dart';

import 'test_helpers.dart';

void main() {
  const phone = Size(420, 900);

  testWidgets('estado de éxito: servidor accesible y Wi-Fi reportado', (tester) async {
    useSize(tester, phone);
    final c = buildController(
      connectivity: [ConnectivityResult.wifi],
      handler: (_) async => http.Response('{"id":1}', 200),
    );
    await tester.pumpWidget(NetLabApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('Servidor accesible'), findsOneWidget);
    expect(c.successCount, 1);
  });

  testWidgets('estado sin conexión: el sistema no reporta red', (tester) async {
    useSize(tester, phone);
    final c = buildController(
      connectivity: [ConnectivityResult.none],
      handler: (_) async => throw const SocketException('Network is unreachable'),
    );
    await tester.pumpWidget(NetLabApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsWidgets);
    expect(c.lastCheck?.verdict.title, 'Sin conexión');
    expect(c.failureCount, 1);
  });

  testWidgets('estado de error HTTP: 500 no se presenta como fallo de red', (tester) async {
    useSize(tester, phone);
    final c = buildController(
      connectivity: [ConnectivityResult.wifi],
      handler: (_) async => http.Response('error', 500),
    );
    await tester.pumpWidget(NetLabApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('El servidor respondió con error HTTP'), findsOneWidget);
    expect(c.httpErrorCount, 1);
    expect(c.failureCount, 0);
  });

  testWidgets('estado de carga: se muestra mientras la petición está pendiente', (tester) async {
    useSize(tester, phone);
    final gate = Completer<http.Response>();
    final c = buildController(
      connectivity: [ConnectivityResult.wifi],
      handler: (_) => gate.future,
    );
    await tester.pumpWidget(NetLabApp(controller: c));
    await tester.pump(); // procesa init()
    await tester.pump();

    expect(find.text('Comprobando servidor…'), findsOneWidget);

    gate.complete(http.Response('{}', 200));
    await tester.pumpAndSettle();
    expect(find.text('Servidor accesible'), findsOneWidget);
  });

  testWidgets('navegación inferior cambia a API REST', (tester) async {
    useSize(tester, phone);
    final c = buildController(
      connectivity: [ConnectivityResult.wifi],
      handler: (_) async => http.Response('{}', 200),
    );
    await tester.pumpWidget(NetLabApp(controller: c));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.http_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Solicitud'), findsOneWidget);
  });
}
