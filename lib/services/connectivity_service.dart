import 'package:connectivity_plus/connectivity_plus.dart';

/// Envoltorio de `connectivity_plus`. Solo informa lo que el SISTEMA reporta
/// (Wi-Fi, datos, Ethernet...). No prueba el acceso real a Internet.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity;

  Connectivity? _connectivity;
  Connectivity get _c => _connectivity ??= Connectivity();

  Future<List<ConnectivityResult>> current() => _c.checkConnectivity();

  Stream<List<ConnectivityResult>> get changes => _c.onConnectivityChanged;
}
