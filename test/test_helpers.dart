import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:netlab/services/api_service.dart';
import 'package:netlab/services/connectivity_service.dart';
import 'package:netlab/services/netlab_controller.dart';

/// Conectividad simulada: solo controla lo que "reporta el sistema".
/// Las peticiones HTTP siguen pasando por ApiService (con MockClient).
class FakeConnectivity extends ConnectivityService {
  FakeConnectivity(this.initial);
  final List<ConnectivityResult> initial;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> current() async => initial;

  @override
  Stream<List<ConnectivityResult>> get changes => _controller.stream;
}

NetLabController buildController({
  required List<ConnectivityResult> connectivity,
  required MockClientHandler handler,
}) =>
    NetLabController(
      connectivity: FakeConnectivity(connectivity),
      api: ApiService(client: MockClient(handler)),
    );

/// Fija el tamaño lógico de la ventana de prueba.
void useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
