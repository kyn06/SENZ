import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/sensor_reading.dart';
import 'ble_config.dart';
import 'sensor_data_parser.dart';
import 'sensor_service.dart';

class BluetoothSensorService extends ChangeNotifier implements SensorService {
  BluetoothSensorService({FlutterReactiveBle? ble})
    : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;
  final SensorDataParser _parser = SensorDataParser();
  final StreamController<SensorReading> _readings =
      StreamController<SensorReading>.broadcast();
  final Map<String, DiscoveredDevice> _devices = {};

  StreamSubscription<BleStatus>? _statusSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _reconnectTimer;
  String? _lastDeviceId;
  String? _lastDeviceName;
  bool _intentionalDisconnect = true;

  BleStatus status = BleStatus.unknown;
  bool isScanning = false;
  bool isConnected = false;
  bool autoReconnect = true;
  String? connectedDeviceId;
  String? connectedDeviceName;
  String? errorMessage;
  String connectionMessage = 'Disconnected';
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices.values);

  @override
  Stream<SensorReading> get readings => _readings.stream;

  @override
  Future<void> start() async {
    try {
      await _ble.initialize();
      await _statusSubscription?.cancel();
      _statusSubscription = _ble.statusStream.listen(
        (value) {
          status = value;
          if (value != BleStatus.ready && isScanning) {
            unawaited(stopScan());
          }
          notifyListeners();
        },
        onError: (Object error) {
          errorMessage = 'Bluetooth status error: $error';
          notifyListeners();
        },
      );
      status = _ble.status;
      notifyListeners();
    } catch (error) {
      errorMessage = 'Bluetooth is unavailable: $error';
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    try {
      await _ble.initialize();
      status = _ble.status;
    } catch (error) {
      errorMessage = 'Could not check Bluetooth status: $error';
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (isScanning) return;
    if (status != BleStatus.ready) {
      errorMessage = status == BleStatus.unauthorized
          ? 'SENZ does not have permission to use Bluetooth. Allow it in this app\'s system permissions, then scan again.'
          : 'Turn on Bluetooth to scan for SENZ devices.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    _devices.clear();
    isScanning = true;
    notifyListeners();
    try {
      _scanSubscription = _ble
          .scanForDevices(
            withServices: const [],
            scanMode: ScanMode.lowLatency,
            requireLocationServicesEnabled: false,
          )
          .listen(
            (device) {
              _devices[device.id] = device;
              notifyListeners();
            },
            onError: (Object error) {
              errorMessage = 'Could not scan for devices: $error';
              isScanning = false;
              notifyListeners();
            },
          );
      await Future<void>.delayed(const Duration(seconds: 12));
      await stopScan();
    } catch (error) {
      errorMessage = 'Could not scan for devices: $error';
      isScanning = false;
      notifyListeners();
    }
  }

  @override
  Future<void> stop() => stopScan();

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (isScanning) {
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connect(DiscoveredDevice device) async {
    await _connectTo(device.id, _displayName(device));
  }

  Future<void> reconnectDevice(String deviceId, String deviceName) =>
      _connectTo(deviceId, deviceName);

  Future<void> _connectTo(String deviceId, String deviceName) async {
    await stopScan();
    await disconnect();
    _lastDeviceId = deviceId;
    _lastDeviceName = deviceName;
    _intentionalDisconnect = false;
    errorMessage = null;
    connectionMessage = 'Connecting to $deviceName…';
    connectedDeviceId = deviceId;
    connectedDeviceName = deviceName;
    _parser.reset();
    notifyListeners();

    try {
      _connectionSubscription = _ble
          .connectToDevice(
            id: deviceId,
            connectionTimeout: const Duration(seconds: 12),
          )
          .listen(
            (update) {
              switch (update.connectionState) {
                case DeviceConnectionState.connecting:
                  connectionMessage = 'Connecting…';
                case DeviceConnectionState.connected:
                  isConnected = true;
                  connectionMessage = 'Connected';
                  errorMessage = null;
                  unawaited(_subscribeToSensorData(deviceId));
                case DeviceConnectionState.disconnecting:
                  connectionMessage = 'Disconnecting…';
                case DeviceConnectionState.disconnected:
                  isConnected = false;
                  connectionMessage = 'Disconnected';
                  unawaited(_notificationSubscription?.cancel());
                  _notificationSubscription = null;
                  if (update.failure != null) {
                    errorMessage = update.failure.toString();
                  }
                  if (!_intentionalDisconnect && autoReconnect) {
                    _scheduleReconnect();
                  }
              }
              notifyListeners();
            },
            onError: (Object error) {
              isConnected = false;
              connectionMessage = 'Connection failed';
              errorMessage = error.toString();
              notifyListeners();
            },
          );
    } catch (error) {
      isConnected = false;
      connectionMessage = 'Connection failed';
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> _subscribeToSensorData(String deviceId) async {
    try {
      await _ble.discoverAllServices(deviceId);
      final services = await _ble.getDiscoveredServices(deviceId);
      Characteristic? tx;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.isNotifiable &&
              characteristic.id == BleConfig.txCharacteristicUuid) {
            tx = characteristic;
            break;
          }
        }
        if (tx != null) break;
      }
      tx ??= _firstNotifiableCharacteristic(services);
      if (tx == null) {
        connectionMessage = 'Connected, but no sensor notifications found';
        errorMessage =
            'Check the ESP32 TX characteristic UUID and notification setup.';
        notifyListeners();
        return;
      }

      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: tx.service.id,
        characteristicId: tx.id,
      );
      _notificationSubscription = _ble
          .subscribeToCharacteristic(characteristic)
          .listen(
            _handleNotification,
            onError: (Object error) {
              errorMessage = 'Sensor notification error: $error';
              notifyListeners();
            },
          );
      connectionMessage = 'Receiving sensor data';
      notifyListeners();
    } catch (error) {
      errorMessage = 'Could not set up sensor notifications: $error';
      notifyListeners();
    }
  }

  Characteristic? _firstNotifiableCharacteristic(List<Service> services) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.isNotifiable) return characteristic;
      }
    }
    return null;
  }

  void _handleNotification(List<int> bytes) {
    try {
      final frames = _parser.addChunk(bytes);
      if (_parser.lastError != null) {
        errorMessage = _parser.lastError;
        notifyListeners();
      }
      for (final frame in frames) {
        _readings.add(
          SensorReading(
            values: frame,
            timestamp: DateTime.now(),
            isSimulated: false,
          ),
        );
      }
    } on FormatException catch (error) {
      errorMessage = 'Ignored invalid sensor message: ${error.message}';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    isConnected = false;
    connectedDeviceId = null;
    connectedDeviceName = null;
    connectionMessage = 'Disconnected';
    _parser.reset();
    notifyListeners();
  }

  void _scheduleReconnect() {
    final deviceId = _lastDeviceId;
    final deviceName = _lastDeviceName;
    if (deviceId == null ||
        deviceName == null ||
        _reconnectTimer?.isActive == true) {
      return;
    }
    connectionMessage = 'Connection lost; retrying…';
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!autoReconnect || _intentionalDisconnect || isConnected) return;
      unawaited(_connectTo(deviceId, deviceName));
    });
  }

  String _displayName(DiscoveredDevice device) =>
      device.name.trim().isEmpty ? device.id : device.name.trim();

  @override
  void dispose() {
    unawaited(stopScan());
    _reconnectTimer?.cancel();
    unawaited(_statusSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    unawaited(_readings.close());
    super.dispose();
  }
}
