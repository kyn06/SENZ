import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/sensor_reading.dart';
import 'bluetooth_sensor_service.dart';
import 'demo_sensor_service.dart';
import 'gesture_recognizer.dart';

enum SensorMode { demo, hardware }

class SenzController extends ChangeNotifier {
  SenzController({
    DemoSensorService? demoService,
    BluetoothSensorService? bluetoothService,
    FlutterTts? speech,
  }) : demo = demoService ?? DemoSensorService(),
       bluetooth = bluetoothService ?? BluetoothSensorService(),
       _speech = speech ?? FlutterTts() {
    _demoSubscription = demo.readings.listen(_onReading);
    _hardwareSubscription = bluetooth.readings.listen(_onReading);
    bluetooth.addListener(_onBluetoothChanged);
    _speech.setStartHandler(() {
      isSpeaking = true;
      notifyListeners();
    });
    _speech.setCompletionHandler(() {
      isSpeaking = false;
      notifyListeners();
    });
    _speech.setErrorHandler((dynamic error) {
      isSpeaking = false;
      speechError = error.toString();
      notifyListeners();
    });
    unawaited(initialize());
  }

  final DemoSensorService demo;
  final BluetoothSensorService bluetooth;
  final FlutterTts _speech;
  final GestureRecognizer _recognizer = GestureRecognizer();
  final List<GestureRecord> _history = [];

  StreamSubscription<SensorReading>? _demoSubscription;
  StreamSubscription<SensorReading>? _hardwareSubscription;
  SensorMode mode = SensorMode.demo;
  ThemeMode themeMode = ThemeMode.light;
  SensorReading? reading;
  String gesture = 'Waiting for demo';
  String speechLanguage = 'en-US';
  String speechSpeed = 'Normal';
  String dataFormat = 'CSV (5 integers)';
  bool bluetoothEnabled = true;
  bool autoReconnect = true;
  bool isSpeaking = false;
  bool isCalibrated = false;
  String? calibrationMessage;
  String? speechError;
  List<int>? _openHandPoseCalibration;
  List<int>? _closedHandPoseCalibration;

  static const _demoOpenValues = [1820, 1750, 1900, 1680, 1800];
  static const _demoClosedValues = [3200, 3150, 3300, 3080, 3180];
  static const _fallbackOpenValues = [1000, 1000, 1000, 1000, 1000];
  static const _fallbackClosedValues = [3200, 3200, 3200, 3200, 3200];

  List<GestureRecord> get history => List.unmodifiable(_history);
  bool get isDemoMode => mode == SensorMode.demo;
  bool get isConnected => bluetooth.isConnected;
  bool get isScanning => bluetooth.isScanning;
  List<DiscoveredDevice> get discoveredDevices => bluetooth.devices;
  bool get hasOpenHandCalibration => _openHandPoseCalibration != null;
  bool get hasClosedHandCalibration => _closedHandPoseCalibration != null;
  bool get canCalibrateHandPose => reading != null && !isDemoMode;

  List<double> get handPose {
    final values = reading?.values;
    if (values == null || values.length != 5) return const [0, 0, 0, 0, 0];
    final open = isDemoMode
        ? _demoOpenValues
        : (_openHandPoseCalibration ?? _fallbackOpenValues);
    final closed = isDemoMode
        ? _demoClosedValues
        : (_closedHandPoseCalibration ?? _fallbackClosedValues);
    return List<double>.generate(5, (index) {
      final span = closed[index] - open[index];
      if (span == 0) return 0;
      final raw = ((values[index] - open[index]) / span).clamp(0.0, 1.0);
      return raw * raw * (3 - 2 * raw);
    });
  }

  Future<void> initialize() async {
    await demo.start();
    await bluetooth.start();
    _applySpeechSettings();
  }

  void _onBluetoothChanged() {
    if (mode == SensorMode.hardware) notifyListeners();
  }

  void _onReading(SensorReading next) {
    if (next.isSimulated != isDemoMode) return;
    reading = next;
    gesture = _recognizer.recognize(next.values);
    final previous = _history.isEmpty ? null : _history.first.name;
    if (gesture != previous) {
      _history.insert(
        0,
        GestureRecord(
          name: gesture,
          timestamp: next.timestamp,
          isSimulated: next.isSimulated,
        ),
      );
      if (_history.length > 100) _history.removeLast();
    }
    notifyListeners();
  }

  Future<void> setMode(SensorMode value) async {
    if (mode == value) return;
    mode = value;
    reading = null;
    gesture = value == SensorMode.demo
        ? 'Waiting for demo'
        : 'Waiting for glove';
    if (value == SensorMode.demo) {
      await bluetooth.disconnect();
      await demo.start();
    } else {
      await demo.stop();
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    await setMode(SensorMode.hardware);
    if (!bluetoothEnabled) {
      bluetooth.errorMessage = 'Enable Bluetooth for this app in Settings.';
      notifyListeners();
      return;
    }
    await bluetooth.startScan();
    notifyListeners();
  }

  Future<void> connect(DiscoveredDevice device) async {
    await setMode(SensorMode.hardware);
    await bluetooth.connect(device);
  }

  Future<void> disconnect() => bluetooth.disconnect();

  Future<void> setBluetoothEnabled(bool value) async {
    bluetoothEnabled = value;
    if (!value) {
      await bluetooth.stopScan();
      await bluetooth.disconnect();
    }
    notifyListeners();
  }

  void setAutoReconnect(bool value) {
    autoReconnect = value;
    bluetooth.autoReconnect = value;
    notifyListeners();
  }

  void captureOpenHandCalibration() {
    final current = reading;
    if (current == null || current.isSimulated) {
      calibrationMessage = 'Connect the glove to capture real sensor values.';
    } else {
      _openHandPoseCalibration = List<int>.unmodifiable(current.values);
      _recognizer.calibrate(current.values);
      isCalibrated = true;
      calibrationMessage = 'Open-hand pose saved.';
    }
    notifyListeners();
  }

  void captureClosedHandCalibration() {
    final current = reading;
    if (current == null || current.isSimulated) {
      calibrationMessage = 'Connect the glove to capture real sensor values.';
    } else {
      _closedHandPoseCalibration = List<int>.unmodifiable(current.values);
      calibrationMessage = 'Closed-hand pose saved.';
    }
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  Future<void> setSpeechLanguage(String value) async {
    speechLanguage = value;
    speechError = null;
    try {
      await _speech.setLanguage(value);
    } catch (error) {
      speechError = 'Could not set speech language: $error';
    }
    notifyListeners();
  }

  Future<void> setSpeechSpeed(String value) async {
    speechSpeed = value;
    await _applySpeechSettings();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
  }

  Future<void> speakGesture() async {
    await speakText(gesture);
  }

  Future<void> speakText(String text) async {
    try {
      await _speech.setLanguage(speechLanguage);
      await _speech.setSpeechRate(_rateForSpeed(speechSpeed));
      await _speech.speak(text);
      isSpeaking = true;
      speechError = null;
    } catch (error) {
      speechError = 'Text to speech is unavailable: $error';
    }
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _speech.stop();
    isSpeaking = false;
    notifyListeners();
  }

  Future<void> _applySpeechSettings() async {
    try {
      await _speech.setLanguage(speechLanguage);
      await _speech.setSpeechRate(_rateForSpeed(speechSpeed));
    } catch (error) {
      speechError = 'Speech settings could not be applied: $error';
    }
  }

  double _rateForSpeed(String value) => switch (value) {
    'Slow' => 0.35,
    'Fast' => 0.65,
    _ => 0.5,
  };

  @override
  void dispose() {
    unawaited(_demoSubscription?.cancel());
    unawaited(_hardwareSubscription?.cancel());
    bluetooth.removeListener(_onBluetoothChanged);
    unawaited(demo.dispose());
    bluetooth.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }
}
