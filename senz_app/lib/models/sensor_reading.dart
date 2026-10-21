class SensorReading {
  SensorReading({
    required List<int> values,
    required this.timestamp,
    required this.isSimulated,
  }) : values = List<int>.unmodifiable(values);

  final List<int> values;
  final DateTime timestamp;
  final bool isSimulated;
}

class GestureRecord {
  const GestureRecord({
    required this.name,
    required this.timestamp,
    required this.isSimulated,
    this.translation,
  });

  final String name;
  final String? translation;
  final DateTime timestamp;
  final bool isSimulated;
}
