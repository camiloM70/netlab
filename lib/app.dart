import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/home_shell.dart';
import 'services/netlab_controller.dart';

/// Raíz de la aplicación. Crea (o recibe, en pruebas) el controlador global
/// y lo libera al destruirse: cancela la suscripción de conectividad y cierra
/// los clientes HTTP.
class NetLabApp extends StatefulWidget {
  const NetLabApp({super.key, this.controller});

  /// Permite inyectar un controlador con servicios simulados en las pruebas.
  final NetLabController? controller;

  @override
  State<NetLabApp> createState() => _NetLabAppState();
}

class _NetLabAppState extends State<NetLabApp> {
  late final NetLabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NetLabController();
    // Comprobación inicial de conectividad y del servidor de pruebas.
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetLab',
      debugShowCheckedModeBanner: false,
      theme: buildNetLabTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(controller: _controller),
    );
  }
}
