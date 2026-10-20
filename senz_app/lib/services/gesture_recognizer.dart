class GestureRecognizer {
  static const _bendThreshold = 2450;

  List<int>? _openHandBaseline;

  bool get isCalibrated => _openHandBaseline != null;

  void calibrate(List<int> openHandReadings) {
    if (openHandReadings.length != 5) return;
    _openHandBaseline = List<int>.unmodifiable(openHandReadings);
  }

  String recognize(List<int> readings) {
    if (readings.length != 5) return 'Waiting for data';
    final baseline = _openHandBaseline;
    final bent = List<bool>.generate(5, (index) {
      if (baseline == null) return readings[index] >= _bendThreshold;
      return (readings[index] - baseline[index]).abs() >= 450;
    });
    final bentCount = bent.where((value) => value).length;

    if (bentCount == 0) return 'Open Hand';
    if (bentCount == 5) return 'Fist';
    if (bent[0] && bent[1] && !bent[2] && !bent[3] && !bent[4]) {
      return 'OK';
    }
    if (bent[0] && !bent[1] && bent[2] && bent[3] && bent[4]) {
      return 'Point';
    }
    return 'Gesture';
  }
}
