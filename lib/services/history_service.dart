import '../models/api_result.dart';
import '../models/history_entry.dart';

/// Historial EN MEMORIA de la sesión (se pierde al cerrar la app, a propósito:
/// evita complejidad innecesaria). Los más recientes van primero.
class HistoryService {
  HistoryService({this.maxEntries = 200});

  final int maxEntries;
  final List<HistoryEntry> _entries = [];
  int _nextId = 1;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  HistoryEntry add(ApiResult result, {String? kind}) {
    final entry = HistoryEntry.fromResult(result, id: _nextId++, kind: kind);
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    return entry;
  }

  void clear() => _entries.clear();

  /// Filtra por tipo/método y/o resultado (null = sin filtro).
  static List<HistoryEntry> apply(
    Iterable<HistoryEntry> source, {
    String? kind,
    Outcome? outcome,
  }) =>
      source
          .where((e) =>
              (kind == null || e.kind == kind) &&
              (outcome == null || e.outcome == outcome))
          .toList();
}
