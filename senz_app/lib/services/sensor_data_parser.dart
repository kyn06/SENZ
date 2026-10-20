import 'dart:convert';

/// Parses five integer ADC readings from newline-delimited BLE notifications.
/// It buffers partial lines and accepts multiple lines in one notification.
class SensorDataParser {
  String _buffer = '';
  String? lastError;

  List<List<int>> addChunk(List<int> bytes) {
    _buffer += utf8.decode(bytes, allowMalformed: false);
    final frames = <List<int>>[];

    while (true) {
      final newline = _buffer.indexOf('\n');
      if (newline < 0) break;
      final line = _buffer.substring(0, newline).replaceAll('\r', '').trim();
      _buffer = _buffer.substring(newline + 1);
      final frame = parseLine(line);
      if (frame != null) {
        lastError = null;
        frames.add(frame);
      } else if (line.isNotEmpty) {
        lastError = 'Expected exactly five integers from 0 to 4095.';
      }
    }

    // Some UART firmwares send one complete CSV frame without a newline.
    final tokens = _buffer.split(',');
    while (tokens.length >= 5) {
      final group = tokens.take(5).join(',');
      final frame = parseLine(group);
      if (frame == null) {
        lastError = 'Expected exactly five integers from 0 to 4095.';
        _buffer = '';
        return frames;
      }
      lastError = null;
      frames.add(frame);
      tokens.removeRange(0, 5);
    }
    _buffer = tokens.join(',');
    return frames;
  }

  List<int>? parseLine(String line) {
    final parts = line.split(',').map((part) => part.trim()).toList();
    if (parts.length != 5 || parts.any((part) => part.isEmpty)) return null;
    final values = parts.map(int.tryParse).toList();
    if (values.any((value) => value == null)) return null;
    final readings = values.cast<int>();
    if (readings.any((value) => value < 0 || value > 4095)) return null;
    return readings;
  }

  void reset() {
    _buffer = '';
    lastError = null;
  }
}
