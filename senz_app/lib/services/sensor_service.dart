import '../models/sensor_reading.dart';

abstract interface class SensorService {
  Stream<SensorReading> get readings;

  Future<void> start();

  Future<void> stop();
}
