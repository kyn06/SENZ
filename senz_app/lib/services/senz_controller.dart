import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/fsl_sign.dart';
import '../models/sensor_reading.dart';
import 'bluetooth_sensor_service.dart';
import 'demo_sensor_service.dart';
import 'sequence_sign_recognizer.dart';
import 'senz_state_store.dart';

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
  final SenzStateStore _stateStore = SenzStateStore();
  final SequenceSignRecognizer _recognizer = SequenceSignRecognizer();
  final List<GestureRecord> _history = [];
  final List<FslSignDefinition> _fslCatalog = [];
  final List<List<int>> _trainingFrames = [];
  final List<List<int>> _liveFrames = [];
  Future<void> _pendingStateWrite = Future<void>.value();

  StreamSubscription<SensorReading>? _demoSubscription;
  StreamSubscription<SensorReading>? _hardwareSubscription;
  SensorMode mode = SensorMode.demo;
  ThemeMode themeMode = ThemeMode.light;
  SensorReading? reading;
  String gesture = 'Waiting for a supported FSL sign';
  FslSignDefinition? recognizedSign;
  bool isCapturingTrainingSample = false;
  bool isLiveTranslationEnabled = false;
  String? trainingMessage;
  String speechLanguage = 'fil-PH';
  String speechSpeed = 'Normal';
  String dataFormat = 'CSV (5 integers)';
  bool bluetoothEnabled = true;
  bool autoReconnect = true;
  bool isSpeaking = false;
  String? calibrationMessage;
  String? speechError;
  List<int>? _openHandPoseCalibration;
  List<int>? _closedHandPoseCalibration;
  List<String> restoredNavigationStack = const ['welcome'];
  bool isRestored = false;
  bool welcomeCompleted = false;
  String? _savedDeviceId;
  String? _savedDeviceName;
  bool _reconnectOnLaunch = false;
  int _liveFrameCount = 0;
  int _candidateWindowCount = 0;
  int _unmatchedWindowCount = 0;
  String? _candidateSignId;
  String? _lastEmittedSignId;

  static const _demoOpenValues = [1820, 1750, 1900, 1680, 1800];
  static const _demoClosedValues = [3200, 3150, 3300, 3080, 3180];
  static const _fallbackOpenValues = [1000, 1000, 1000, 1000, 1000];
  static const _fallbackClosedValues = [3200, 3200, 3200, 3200, 3200];
  static const _liveWindowLength = 12;
  static const _liveEvaluationInterval = 3;
  static const _stableWindowsRequired = 3;
  static const _releaseWindowsRequired = 3;

  List<GestureRecord> get history => List.unmodifiable(_history);
  List<FslSignDefinition> get fslSigns => List.unmodifiable(_fslCatalog);
  bool get isDemoMode => mode == SensorMode.demo;
  bool get isConnected => bluetooth.isConnected;
  bool get isScanning => bluetooth.isScanning;
  List<DiscoveredDevice> get discoveredDevices => bluetooth.devices;
  bool get hasOpenHandCalibration => _openHandPoseCalibration != null;
  bool get hasClosedHandCalibration => _closedHandPoseCalibration != null;
  bool get isCalibrated => hasOpenHandCalibration && hasClosedHandCalibration;
  bool get canCalibrateHandPose => reading != null && !isDemoMode;
  bool get hasFslSignTemplates =>
      _fslCatalog.any((sign) => sign.examples.isNotEmpty);
  int get trainingFrameCount => _trainingFrames.length;
  bool get hasPendingTrainingSample =>
      !isCapturingTrainingSample && _trainingFrames.length >= 6;
  bool get canRecordFslSample =>
      !isDemoMode && isConnected && isCalibrated && !isCapturingTrainingSample;

  String get liveTranslationMessage {
    if (!isLiveTranslationEnabled) {
      return 'Open Translate to begin live listening.';
    }
    if (isDemoMode) {
      return 'Switch to Hardware Mode to use live FSL translation.';
    }
    if (!isConnected) return 'Connect the BLE glove to begin live translation.';
    if (!isCalibrated) {
      return 'Capture open-hand and closed-hand calibration in Settings.';
    }
    if (!hasFslSignTemplates) {
      return 'Add FSL-reviewed sign examples on the FSL Sign Data page.';
    }
    return 'Listening for supported signs. Perform one sign at a time.';
  }

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
    Map<String, dynamic> saved = {};
    try {
      saved = await _stateStore.load();
    } catch (_) {
      // Start with defaults if the local preferences snapshot cannot be read.
    }
    _restoreState(saved);
    if (mode == SensorMode.demo) {
      await demo.start();
    } else {
      await demo.stop();
    }
    await bluetooth.start();
    _applySpeechSettings();
    isRestored = true;
    notifyListeners();
    if (mode == SensorMode.hardware &&
        bluetoothEnabled &&
        autoReconnect &&
        _reconnectOnLaunch &&
        _savedDeviceId != null) {
      final granted = await requestBluetoothPermissions();
      if (granted) {
        await bluetooth.refreshStatus();
        await bluetooth.reconnectDevice(
          _savedDeviceId!,
          _savedDeviceName ?? _savedDeviceId!,
        );
      } else {
        notifyListeners();
      }
    }
  }

  void _restoreState(Map<String, dynamic> saved) {
    mode = saved['sensorMode'] == 'hardware'
        ? SensorMode.hardware
        : SensorMode.demo;
    themeMode = switch (saved['themeMode']) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    // Keep the app's spoken output in Filipino, including for users upgrading
    // from a saved English speech-language preference.
    speechLanguage = 'fil-PH';
    speechSpeed = saved['speechSpeed'] as String? ?? speechSpeed;
    autoReconnect = saved['autoReconnect'] as bool? ?? autoReconnect;
    bluetooth.autoReconnect = autoReconnect;
    bluetoothEnabled = saved['bluetoothEnabled'] as bool? ?? bluetoothEnabled;
    _savedDeviceId = saved['deviceId'] as String?;
    _savedDeviceName = saved['deviceName'] as String?;
    _reconnectOnLaunch = saved['reconnectOnLaunch'] as bool? ?? false;
    _openHandPoseCalibration = _intList(saved['openHandCalibration']);
    _closedHandPoseCalibration = _intList(saved['closedHandCalibration']);
    _fslCatalog
      ..clear()
      ..addAll(_readFslCatalog(saved['fslCatalog']));

    final navigation = saved['navigationStack'];
    if (navigation is List) {
      restoredNavigationStack = navigation.whereType<String>().toList();
      if (restoredNavigationStack.isEmpty) {
        restoredNavigationStack = const ['welcome'];
      }
    }
    welcomeCompleted =
        saved['welcomeCompleted'] as bool? ??
        restoredNavigationStack.contains('home');

    final history = saved['history'];
    if (history is List) {
      _history
        ..clear()
        ..addAll(
          history.whereType<Map>().take(100).map((entry) {
            return GestureRecord(
              name: entry['name'] as String? ?? 'Unknown sign',
              translation: entry['translation'] as String?,
              timestamp:
                  DateTime.tryParse(entry['timestamp'] as String? ?? '') ??
                  DateTime.now(),
              isSimulated: entry['isSimulated'] as bool? ?? false,
            );
          }),
        );
    }
  }

  List<FslSignDefinition> _readFslCatalog(Object? value) {
    if (value is! List) return FslSignCatalog.signs;
    final signs = <FslSignDefinition>[];
    for (final entry in value.whereType<Map>()) {
      final id = entry['id'];
      final displayName = entry['displayName'];
      final translation = entry['translation'];
      final rawExamples = entry['examples'];
      if (id is! String ||
          displayName is! String ||
          translation is! String ||
          rawExamples is! List) {
        continue;
      }
      final examples = <List<List<double>>>[];
      for (final rawExample in rawExamples) {
        if (rawExample is! List) continue;
        final frames = <List<double>>[];
        for (final rawFrame in rawExample) {
          if (rawFrame is! List || rawFrame.length != 5) continue;
          final values = rawFrame
              .whereType<num>()
              .map((n) => n.toDouble())
              .toList();
          if (values.length == 5) frames.add(values);
        }
        if (frames.length >= 2) examples.add(frames);
      }
      if (id.isNotEmpty && displayName.isNotEmpty && examples.isNotEmpty) {
        signs.add(
          FslSignDefinition(
            id: id,
            displayName: displayName,
            translation: translation,
            examples: examples,
          ),
        );
      }
    }
    return signs;
  }

  List<int>? _intList(Object? value) => value is List
      ? value.whereType<num>().map((item) => item.toInt()).toList()
      : null;

  void updateNavigationStack(List<String> names) {
    restoredNavigationStack = List.unmodifiable(names);
    _saveState();
  }

  void completeWelcome() {
    if (welcomeCompleted) return;
    welcomeCompleted = true;
    _saveState();
  }

  Map<String, Object?> _stateSnapshot() => {
    'sensorMode': mode.name,
    'themeMode': switch (themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    },
    'speechLanguage': speechLanguage,
    'speechSpeed': speechSpeed,
    'autoReconnect': autoReconnect,
    'bluetoothEnabled': bluetoothEnabled,
    'deviceId': _savedDeviceId,
    'deviceName': _savedDeviceName,
    'reconnectOnLaunch': _reconnectOnLaunch,
    'openHandCalibration': _openHandPoseCalibration,
    'closedHandCalibration': _closedHandPoseCalibration,
    'navigationStack': restoredNavigationStack,
    'welcomeCompleted': welcomeCompleted,
    'fslCatalog': _fslCatalog
        .map(
          (sign) => {
            'id': sign.id,
            'displayName': sign.displayName,
            'translation': sign.translation,
            'examples': sign.examples,
          },
        )
        .toList(),
    'history': _history
        .map(
          (entry) => {
            'name': entry.name,
            'translation': entry.translation,
            'timestamp': entry.timestamp.toIso8601String(),
            'isSimulated': entry.isSimulated,
          },
        )
        .toList(),
  };

  void _saveState() {
    final snapshot = _stateSnapshot();
    _pendingStateWrite = _pendingStateWrite.then((_) async {
      try {
        await _stateStore.save(snapshot);
      } catch (_) {
        // Keep the live app usable if local storage is temporarily unavailable.
      }
    });
  }

  Future<void> persistState() async {
    _saveState();
    await _pendingStateWrite;
  }

  Future<bool> requestBluetoothPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      final requiredPermissions = sdk >= 31
          ? <Permission>[Permission.bluetoothScan, Permission.bluetoothConnect]
          : <Permission>[Permission.locationWhenInUse];
      final statuses = await requiredPermissions.request();
      final granted = statuses.values.every((status) => status.isGranted);
      if (!granted) {
        final permissionName = sdk >= 31 ? 'Nearby devices' : 'Location';
        bluetooth.errorMessage =
            'SENZ needs $permissionName permission to scan and connect. Allow it in the app permissions.';
      }
      return granted;
    } catch (error) {
      bluetooth.errorMessage = 'Could not request Bluetooth permission: $error';
      return false;
    }
  }

  void _onBluetoothChanged() {
    if (mode == SensorMode.hardware) {
      if (!isConnected) _resetLiveRecognition(clearResult: true);
      notifyListeners();
    }
  }

  void _onReading(SensorReading next) {
    if (next.isSimulated != isDemoMode) return;
    reading = next;
    if (isCapturingTrainingSample && !next.isSimulated) {
      _trainingFrames.add(next.values);
      if (_trainingFrames.length > 300) _trainingFrames.removeAt(0);
    }
    if (isLiveTranslationEnabled && !next.isSimulated) {
      _processLiveReading(next.values);
    }
    notifyListeners();
  }

  void beginTrainingSample() {
    if (isDemoMode) {
      trainingMessage =
          'Switch to Hardware Mode before recording real FSL data.';
    } else if (!isConnected) {
      trainingMessage = 'Connect the BLE glove before recording an example.';
    } else if (!isCalibrated) {
      trainingMessage = 'Capture open-hand and closed-hand calibration first.';
    } else {
      _trainingFrames.clear();
      isCapturingTrainingSample = true;
      trainingMessage =
          'Perform one FSL-reviewed sign, then stop the recording.';
    }
    notifyListeners();
  }

  void stopTrainingSample() {
    if (!isCapturingTrainingSample) return;
    isCapturingTrainingSample = false;
    trainingMessage = _trainingFrames.length < 6
        ? 'Sample too short. Record the sign again.'
        : '${_trainingFrames.length} sensor frames captured. Save this example or record it again.';
    notifyListeners();
  }

  String? saveTrainingSample({
    required String displayName,
    required String translation,
  }) {
    final label = displayName.trim();
    final spokenText = translation.trim();
    if (label.isEmpty || spokenText.isEmpty) {
      return 'Enter the FSL sign name and Filipino word or phrase.';
    }
    if (isCapturingTrainingSample) {
      return 'Stop the recording before saving the example.';
    }
    if (!isCalibrated) {
      return 'Capture open-hand and closed-hand calibration first.';
    }
    if (_trainingFrames.length < 6) {
      return 'Record at least six sensor frames first.';
    }
    if (List<int>.generate(
      5,
      (index) =>
          _closedHandPoseCalibration![index] - _openHandPoseCalibration![index],
    ).contains(0)) {
      return 'The calibration poses are too similar. Recalibrate before saving.';
    }

    final signId = label.toLowerCase();
    final existingIndex = _fslCatalog.indexWhere((sign) => sign.id == signId);
    if (existingIndex >= 0 &&
        _fslCatalog[existingIndex].translation.toLowerCase() !=
            spokenText.toLowerCase()) {
      return 'This sign name already has a different Filipino translation.';
    }

    final example = _trainingFrames
        .map(
          (frame) => List<double>.generate(5, (channel) {
            final span =
                _closedHandPoseCalibration![channel] -
                _openHandPoseCalibration![channel];
            if (span == 0) return 0;
            return ((frame[channel] - _openHandPoseCalibration![channel]) /
                    span)
                .clamp(0.0, 1.0)
                .toDouble();
          }),
        )
        .toList();

    if (existingIndex >= 0) {
      final existing = _fslCatalog[existingIndex];
      _fslCatalog[existingIndex] = FslSignDefinition(
        id: existing.id,
        displayName: existing.displayName,
        translation: existing.translation,
        examples: [...existing.examples, example],
      );
    } else {
      _fslCatalog.add(
        FslSignDefinition(
          id: signId,
          displayName: label,
          translation: spokenText,
          examples: [example],
        ),
      );
    }
    _trainingFrames.clear();
    trainingMessage = 'Example saved. Record more variations for this sign.';
    _saveState();
    notifyListeners();
    return null;
  }

  void deleteFslSign(String id) {
    _fslCatalog.removeWhere((sign) => sign.id == id);
    _saveState();
    notifyListeners();
  }

  void startLiveTranslation() {
    isLiveTranslationEnabled = true;
    _resetLiveRecognition(clearResult: true);
    notifyListeners();
  }

  void stopLiveTranslation() {
    isLiveTranslationEnabled = false;
    _resetLiveRecognition(clearResult: false);
  }

  void _processLiveReading(List<int> values) {
    if (!isConnected || !isCalibrated || !hasFslSignTemplates) {
      _liveFrames.clear();
      _liveFrameCount = 0;
      return;
    }
    _liveFrames.add(values);
    if (_liveFrames.length > _liveWindowLength) _liveFrames.removeAt(0);
    _liveFrameCount++;
    if (_liveFrames.length < _liveWindowLength ||
        _liveFrameCount % _liveEvaluationInterval != 0) {
      return;
    }

    final match = _recognizer.recognize(
      _liveFrames,
      openHandBaseline: _openHandPoseCalibration!,
      closedHandBaseline: _closedHandPoseCalibration!,
      signs: _fslCatalog,
    );
    if (match == null) {
      _unmatchedWindowCount++;
      _candidateSignId = null;
      _candidateWindowCount = 0;
      if (_unmatchedWindowCount >= _releaseWindowsRequired) {
        _lastEmittedSignId = null;
        if (recognizedSign != null) {
          recognizedSign = null;
          gesture = 'Listening for a supported FSL sign';
        }
      }
      return;
    }

    _unmatchedWindowCount = 0;
    if (_candidateSignId == match.sign.id) {
      _candidateWindowCount++;
    } else {
      _candidateSignId = match.sign.id;
      _candidateWindowCount = 1;
    }
    if (_candidateWindowCount < _stableWindowsRequired ||
        _lastEmittedSignId == match.sign.id) {
      return;
    }

    _lastEmittedSignId = match.sign.id;
    recognizedSign = match.sign;
    gesture = match.sign.displayName;
    _history.insert(
      0,
      GestureRecord(
        name: match.sign.displayName,
        timestamp: DateTime.now(),
        isSimulated: false,
        translation: match.sign.translation,
      ),
    );
    if (_history.length > 100) _history.removeLast();
    _saveState();
    unawaited(speakText(match.sign.translation));
  }

  void _resetLiveRecognition({required bool clearResult}) {
    _liveFrames.clear();
    _liveFrameCount = 0;
    _candidateWindowCount = 0;
    _unmatchedWindowCount = 0;
    _candidateSignId = null;
    _lastEmittedSignId = null;
    if (clearResult) {
      recognizedSign = null;
      gesture = 'Waiting for a supported FSL sign';
    }
  }

  Future<void> setMode(SensorMode value) async {
    if (mode == value) return;
    mode = value;
    reading = null;
    isCapturingTrainingSample = false;
    _trainingFrames.clear();
    _resetLiveRecognition(clearResult: true);
    recognizedSign = null;
    if (value == SensorMode.demo) {
      await bluetooth.disconnect();
      await demo.start();
    } else {
      await demo.stop();
    }
    _saveState();
    notifyListeners();
  }

  Future<void> startScan() async {
    await setMode(SensorMode.hardware);
    if (!bluetoothEnabled) {
      bluetooth.errorMessage = 'Enable Bluetooth for this app in Settings.';
      notifyListeners();
      return;
    }
    if (!await requestBluetoothPermissions()) {
      notifyListeners();
      return;
    }
    await bluetooth.refreshStatus();
    await bluetooth.startScan();
    notifyListeners();
  }

  Future<void> connect(DiscoveredDevice device) async {
    await setMode(SensorMode.hardware);
    _savedDeviceId = device.id;
    _savedDeviceName = device.name.trim().isEmpty
        ? device.id
        : device.name.trim();
    _reconnectOnLaunch = true;
    await bluetooth.connect(device);
    _saveState();
  }

  Future<void> disconnect() async {
    _reconnectOnLaunch = false;
    await bluetooth.disconnect();
    _saveState();
  }

  Future<void> setBluetoothEnabled(bool value) async {
    bluetoothEnabled = value;
    if (!value) {
      await bluetooth.stopScan();
      await bluetooth.disconnect();
    }
    _saveState();
    notifyListeners();
  }

  void setAutoReconnect(bool value) {
    autoReconnect = value;
    bluetooth.autoReconnect = value;
    _saveState();
    notifyListeners();
  }

  void captureOpenHandCalibration() {
    final current = reading;
    if (current == null || current.isSimulated) {
      calibrationMessage = 'Connect the glove to capture real sensor values.';
    } else {
      _openHandPoseCalibration = List<int>.unmodifiable(current.values);
      calibrationMessage = 'Open-hand pose saved.';
    }
    _saveState();
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
    _saveState();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveState();
    notifyListeners();
  }

  Future<void> setSpeechSpeed(String value) async {
    speechSpeed = value;
    await _applySpeechSettings();
    _saveState();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    _saveState();
    notifyListeners();
  }

  Future<void> speakGesture() async {
    final sign = recognizedSign;
    if (sign != null) await speakText(sign.translation);
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
