import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/endpoints.dart';
import '../core/utils/format.dart';
import '../models/api_result.dart';
import '../models/connectivity_snapshot.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'diagnostics_service.dart';
import 'dio_api_service.dart';
import 'history_service.dart';

/// Estado global de la sesión. Une los servicios y notifica a la interfaz.
/// Es el único lugar que se suscribe a la conectividad: se cancela en [dispose].
class NetLabController extends ChangeNotifier {
  NetLabController({
    ConnectivityService? connectivity,
    ApiService? api,
    DioApiService? dioApi,
    HistoryService? history,
    this.healthUrl = Endpoints.healthCheck,
    this.autoCheckDelay = const Duration(seconds: 1),
  })  : connectivity = connectivity ?? ConnectivityService(),
        api = api ?? ApiService(),
        history = history ?? HistoryService() {
    this.dioApi = dioApi ?? DioApiService(onLog: _addDioLog);
    diagnostics = DiagnosticsService(this.api);
  }

  final ConnectivityService connectivity;
  final ApiService api;
  late final DioApiService dioApi;
  late final DiagnosticsService diagnostics;
  final HistoryService history;
  final String healthUrl;
  final Duration autoCheckDelay;

  StreamSubscription<dynamic>? _subscription;
  Timer? _autoCheckTimer;
  bool _disposed = false;

  // --- Conectividad reportada por el sistema ---
  ConnectivitySnapshot? snapshot;
  final List<ConnectivitySnapshot> events = []; // más reciente primero

  // --- Servidor de pruebas (petición HTTP real) ---
  ServerCheck? lastCheck;
  bool checking = false;

  // --- Contadores de la sesión (no se reinician al limpiar el historial) ---
  int successCount = 0;
  int httpErrorCount = 0;
  int failureCount = 0;
  int get failedTotal => httpErrorCount + failureCount;
  ApiResult? lastResult;

  // --- Trazas del interceptor de Dio ---
  final List<String> dioLog = [];

  Future<void> init() async {
    try {
      _setSnapshot(
        ConnectivitySnapshot(await connectivity.current(), DateTime.now(),
            initial: true),
      );
    } catch (_) {
      // Si la plataforma no responde, snapshot queda en null ("desconocido").
    }
    // Una sola suscripción durante toda la vida del controlador.
    _subscription ??= connectivity.changes.listen(
      (results) {
        _setSnapshot(ConnectivitySnapshot(results, DateTime.now()));
        _scheduleAutoCheck();
      },
      onError: (Object _) {},
    );
    await runServerCheck();
  }

  void _setSnapshot(ConnectivitySnapshot s) {
    snapshot = s;
    events.insert(0, s);
    if (events.length > 30) events.removeLast();
    _notify();
  }

  /// Tras un cambio de red, comprueba el servidor (con un pequeño retardo
  /// para que el sistema termine de configurar la red).
  void _scheduleAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer(autoCheckDelay, () {
      if (!_disposed) unawaited(runServerCheck());
    });
  }

  bool get _offline => snapshot?.isOffline ?? false;

  /// Comprueba el servidor de pruebas con una petición HTTP real.
  Future<ServerCheck?> runServerCheck({String? url}) async {
    if (checking) return lastCheck;
    checking = true;
    _notify();
    final raw = await diagnostics.probe(url ?? healthUrl);
    final result = raw.withOfflineHint(_offline);
    lastCheck = ServerCheck(result, classifyResult(result));
    checking = false;
    _record(result, kind: 'DIAGNÓSTICO');
    return lastCheck;
  }

  /// Petición del explorador REST (paquete `http`).
  Future<ApiResult> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    String? body,
  }) async {
    final raw =
        await api.send(method: method, url: url, headers: headers, body: body);
    final result = raw.withOfflineHint(_offline);
    _record(result);
    return result;
  }

  /// Escenario de depuración con Dio.
  Future<ApiResult> runDioScenario(DioScenario scenario) async {
    final raw = await dioApi.request(
      url: scenario.url,
      connectTimeout: scenario.connectTimeout,
    );
    final result = raw.withOfflineHint(_offline);
    _record(result, kind: 'DIO');
    return result;
  }

  void _record(ApiResult r, {String? kind}) {
    history.add(r, kind: kind);
    lastResult = r;
    switch (r.outcome) {
      case Outcome.success:
        successCount++;
      case Outcome.httpError:
        httpErrorCount++;
      case Outcome.failure:
        failureCount++;
    }
    _notify();
  }

  void clearHistory() {
    history.clear();
    _notify();
  }

  void _addDioLog(String line) {
    dioLog.insert(0, '${formatTime(DateTime.now())}  $line');
    if (dioLog.length > 50) dioLog.removeLast();
    _notify();
  }

  void clearDioLog() {
    dioLog.clear();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoCheckTimer?.cancel();
    _subscription?.cancel();
    api.close();
    dioApi.close();
    super.dispose();
  }
}
