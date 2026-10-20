import 'dart:async';

import '../models/sensor_reading.dart';
import 'sensor_service.dart';

class DemoSensorService implements SensorService {
  final _controller = StreamController<SensorReading>.broadcast();
  Timer? _timer;
  int _tick = 0;

  static const _poses = <List<int>>[
    [1820, 1750, 1900, 1680, 1800], // Open hand
    [3200, 3150, 3300, 3080, 3180], // Fist
    [3150, 3100, 1850, 1720, 1810], // OK
    [3150, 1780, 3200, 3100, 3180], // Point
  ];

  @override
  Stream<SensorReading> get readings => _controller.stream;

  @override
  Future<void> start() async {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      _tick++;
      const ticksPerPose = 18;
      final poseIndex = (_tick ~/ ticksPerPose) % _poses.length;
      final nextIndex = (poseIndex + 1) % _poses.length;
      final progress = (_tick % ticksPerPose) / ticksPerPose;
      final smoothProgress = progress * progress * (3 - 2 * progress);
      final values = List<int>.generate(5, (index) {
        final from = _poses[poseIndex][index];
        final to = _poses[nextIndex][index];
        final movement = (to - from) * smoothProgress;
        final sensorJitter = ((_tick + index * 3) % 7) - 3;
        return (from + movement + sensorJitter).round();
      });
      _controller.add(
        SensorReading(
          values: values,
          timestamp: DateTime.now(),
          isSimulated: true,
        ),
      );
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
