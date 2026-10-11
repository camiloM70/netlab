import 'package:connectivity_plus/connectivity_plus.dart';

const Map<ConnectivityResult, String> _names = {
  ConnectivityResult.wifi: 'Wi-Fi',
  ConnectivityResult.mobile: 'Datos móviles',
  ConnectivityResult.ethernet: 'Ethernet',
  ConnectivityResult.vpn: 'VPN',
  ConnectivityResult.bluetooth: 'Bluetooth',
  ConnectivityResult.other: 'Otra red',
  ConnectivityResult.none: 'Sin conexión',
};

String connectivityName(ConnectivityResult r) => _names[r] ?? 'Otra red';

/// Estado de conectividad REPORTADO POR EL SISTEMA en un instante.
/// No garantiza que haya acceso real a Internet.
class ConnectivitySnapshot {
  const ConnectivitySnapshot(this.results, this.at, {this.initial = false});

  final List<ConnectivityResult> results;
  final DateTime at;
  final bool initial;

  bool get isOffline =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  List<ConnectivityResult> get active =>
      results.where((r) => r != ConnectivityResult.none).toList();

  String get label =>
      isOffline ? 'Sin conexión' : active.map(connectivityName).join(' + ');
}
