import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/netlab_controller.dart';
import '../api_explorer/api_explorer_screen.dart';
import '../connectivity/diagnostics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';

/// Navegación principal: barra inferior en móvil y riel lateral en pantallas anchas.
/// Se usa IndexedStack para CONSERVAR el estado de cada pantalla al cambiar de pestaña.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final NetLabController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final List<Widget> _pages;

  static const _destinations = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Inicio'),
    (Icons.http_outlined, Icons.http, 'API REST'),
    (Icons.network_check_outlined, Icons.network_check, 'Diagnóstico'),
    (Icons.history_outlined, Icons.history, 'Historial'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(controller: widget.controller, onNavigate: _go),
      ApiExplorerScreen(controller: widget.controller, onOpenHistory: () => _go(3)),
      DiagnosticsScreen(controller: widget.controller),
      HistoryScreen(controller: widget.controller),
    ];
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      final body = IndexedStack(index: _index, children: _pages);
      return Scaffold(
        body: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _go,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: NetColors.surface,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.$1),
                          selectedIcon: Icon(d.$2),
                          label: Text(d.$3),
                        ),
                    ],
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _go,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.$1),
                      selectedIcon: Icon(d.$2),
                      label: d.$3,
                    ),
                ],
              ),
      );
    });
  }
}
