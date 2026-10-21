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

The FSL catalog starts empty in `lib/models/fsl_sign.dart`. Open **Settings → FSL Sign Data** to add a reviewer-approved sign label, Filipino phrase, and one or more recordings from the connected, calibrated BLE glove. Those normalized examples are saved locally with app state. The capture controls are disabled in Demo Mode so simulated values cannot enter the FSL catalog.

When **Translate** is open, the app continuously compares a rolling 12-reading window against the saved examples. It requires a stable match across repeated windows before adding a history entry and speaking the Filipino phrase. It unlocks the same sign after several unmatched windows so the user can sign it again. This is an initial real-time prototype algorithm; its distance threshold and behavior need testing with the actual glove and signer-separated FSL recordings.

No FSL examples are included by default. The catalog must be populated with FSL-reviewed vocabulary and recordings before translation can recognize anything. The app cannot independently verify that an operator-entered label is a valid FSL sign. Simulated demo readings are never treated as FSL.

The current BLE payload contains only five flex readings. It does not report palm orientation or hand motion, and the app has not been checked against the physical glove. Before choosing a one-hand vocabulary, check which signs the glove can distinguish. Keep the five flex channels; if selected signs require orientation or movement, agree on an IMU and a versioned BLE payload with the firmware team. Record sample timing, channel units/ranges, sensor calibration, and any IMU axis/units in that protocol before adding parser support. Recognition distances and thresholds also need tuning and signer-separated validation data before making accuracy claims.

## Code layout

- `lib/screens/` contains Welcome, Home, Sensor Readings, FSL Sign Data, real-time Gesture Translation, History, and Settings screens.
- `lib/services/` separates BLE, parsing, demo readings, sequence recognition, local state storage, and shared app state.
- `lib/models/fsl_sign.dart` defines the FSL-reviewed catalog structure and example sequences.
- `lib/models/sensor_reading.dart` defines timestamped readings and recognition history entries.

The BLE UUIDs and five-value format are development assumptions. The app has not been tested against physical SENZ/ESP32 hardware.
