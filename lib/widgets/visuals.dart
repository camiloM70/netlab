import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/api_result.dart';
import '../models/connectivity_snapshot.dart';
import '../models/severity.dart';

IconData connectivityIcon(ConnectivitySnapshot? s) {
  if (s == null) return Icons.sync;
  if (s.isOffline) return Icons.signal_wifi_off;
  const icons = {
    ConnectivityResult.wifi: Icons.wifi,
    ConnectivityResult.mobile: Icons.signal_cellular_alt,
    ConnectivityResult.ethernet: Icons.settings_ethernet,
    ConnectivityResult.vpn: Icons.vpn_lock,
    ConnectivityResult.bluetooth: Icons.bluetooth,
  };
  return icons[s.active.first] ?? Icons.public;
}

Severity outcomeSeverity(Outcome o) => switch (o) {
      Outcome.success => Severity.ok,
      Outcome.httpError => Severity.warn,
      Outcome.failure => Severity.error,
    };

IconData outcomeIcon(Outcome o) => switch (o) {
      Outcome.success => Icons.check_circle_outline,
      Outcome.httpError => Icons.warning_amber_rounded,
      Outcome.failure => Icons.cloud_off,
    };
