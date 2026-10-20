import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Provisional Nordic UART Service IDs. Confirm these against ESP32 firmware.
class BleConfig {
  static final serviceUuid = Uuid.parse('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final txCharacteristicUuid = Uuid.parse(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );
  static final rxCharacteristicUuid = Uuid.parse(
    '6E400002-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  const BleConfig._();
}
