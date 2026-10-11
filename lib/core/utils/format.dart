String _two(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

String formatDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${formatTime(d)}';

String formatDuration(Duration d) {
  final ms = d.inMilliseconds;
  return ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(2)} s';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(1)} KB';
}
