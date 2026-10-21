# SENZ

Flutter prototype for a flex-sensor glove. Demo Mode generates simulated five-finger readings for the interface; those readings are not FSL signs or recognition examples.

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

Sensor notifications contain five comma-separated integers in Thumb, Index, Middle, Ring, Little order, for example `1820,1750,1900,1680,1800`. Values are expected in the 0–4095 range. Newline-delimited and split notifications are supported. The parser ignores malformed frames and only emits valid readings. The current app does not send commands to RX.

## FSL recognition status

The translation screen can capture one time-ordered sensor sequence, normalize it with the user's open/closed hand calibration, and compare it with predefined examples in `lib/models/fsl_sign.dart`. That catalog is intentionally empty until an FSL-only vocabulary, meanings, variants, and recordings are reviewed with FSL signers. No ASL signs are included. With no examples configured, a capture correctly returns **Not recognized**; simulated demo readings are never treated as FSL.

The current BLE payload contains only five flex readings. It does not report palm orientation or hand motion, and the app has not been checked against the physical glove. Before choosing a one-hand vocabulary, check which signs the glove can distinguish. Keep the five flex channels; if selected signs require orientation or movement, agree on an IMU and a versioned BLE payload with the firmware team. Record sample timing, channel units/ranges, sensor calibration, and any IMU axis/units in that protocol before adding parser support. Recognition distances and thresholds also need tuning and signer-separated validation data before making accuracy claims.

## Code layout

- `lib/screens/` contains Welcome, Dashboard, Sensor Readings, Gesture Translation, History, and Settings screens.
- `lib/services/` separates BLE, parsing, demo readings, sequence recognition, and shared app state.
- `lib/models/fsl_sign.dart` defines the FSL-reviewed catalog structure and example sequences.
- `lib/models/sensor_reading.dart` defines timestamped readings and recognition history entries.

The BLE UUIDs and five-value format are development assumptions. The app has not been tested against physical SENZ/ESP32 hardware.
