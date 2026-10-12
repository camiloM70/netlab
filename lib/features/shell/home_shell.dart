import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/netlab_controller.dart';
import '../../widgets/responsive.dart';
import '../api_explorer/api_explorer_screen.dart';
import '../connectivity/diagnostics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';

/// Navegación adaptable:
/// - móvil (<600 dp de ancho, o poca altura): barra inferior;
/// - tableta (600–1023): riel lateral con etiquetas;
/// - pantalla grande (≥1024): riel extendido con la marca.
/// IndexedStack conserva el estado de cada pantalla al cambiar de pestaña.
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
      // En horizontal con poca altura el riel no cabría: se usa la barra inferior.
      final useRail = c.maxWidth >= Breakpoints.medium && c.maxHeight >= 420;
      final extended = c.maxWidth >= Breakpoints.expanded && c.maxHeight >= 520;
      final body = IndexedStack(index: _index, children: _pages);

      return Scaffold(
        body: useRail
            ? Row(
                children: [
                  SafeArea(
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: _go,
                      extended: extended,
                      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: NetSpacing.lg),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hub_outlined, color: NetColors.accent),
                            if (extended) ...[
                              const SizedBox(width: NetSpacing.sm),
                              Text('NetLab', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ],
                        ),
                      ),
                      destinations: [
                        for (final d in _destinations)
                          NavigationRailDestination(
                            icon: Icon(d.$1),
                            selectedIcon: Icon(d.$2),
                            label: Text(d.$3),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: NetColors.border),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _go,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
                ],
              ),
      );
    });
  }
}
