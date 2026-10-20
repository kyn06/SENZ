# SENZ

Flutter prototype for the SENZ flex-sensor glove. The app opens in Demo Mode, where it generates changing five-finger readings and predefined demo gestures without requiring a BLE device. Demo labels and sensor screens identify simulated data explicitly. The gesture patterns are for interface development and are not validated sign-language translation.

## Run

```sh
flutter pub get
flutter run
```

Use **Settings → Sensor Mode → Hardware Mode** to scan for a BLE device. The app scans nearby devices, lets you select one, connects, and listens for notifications. Android and iOS BLE permission declarations are included in their platform configuration.

## Prototype BLE format

The initial configuration is in `lib/services/ble_config.dart`. It uses provisional Nordic UART Service UUIDs; confirm or replace them when the ESP32 firmware is available:

- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- TX notifications: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- RX reserved for future commands: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`

Sensor notifications use five comma-separated integers in Thumb, Index, Middle, Ring, Little order, for example `1820,1750,1900,1680,1800`. Newline-delimited and split notifications are supported. The parser ignores malformed frames and only emits valid readings. The current app does not send commands to RX.

## Code layout

- `lib/screens/` contains Welcome, Dashboard, Sensor Readings, Gesture Translation, History, and Settings screens.
- `lib/services/` separates demo readings, BLE, parsing, gesture patterns, and shared app state.
- `lib/models/sensor_reading.dart` defines a timestamped five-finger reading and its simulated-data marker.

The BLE UUIDs and data format are development assumptions only. The app has not been tested against physical SENZ/ESP32 hardware.
