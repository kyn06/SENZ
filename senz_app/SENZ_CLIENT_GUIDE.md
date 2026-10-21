# SENZ Client Guide

**App:** SENZ  
**Version:** 1.0.0 (Draft)  
**Status:** Prototype development  
**Platform:** Android; iOS support is planned

## What is SENZ?

SENZ is a mobile application being developed alongside a sensor glove. The proposed system uses five flex sensors to measure finger bending, then matches sensor patterns to a limited set of predefined, one-hand Filipino Sign Language (FSL) gestures. When a supported gesture is recognized, the app will display its associated word or phrase and speak it using Filipino text-to-speech.

SENZ is intended to support communication. It does not translate every FSL sign and is not a replacement for a qualified sign language interpreter.

### Short client explanation

“SENZ is a mobile app and sensor-glove prototype for recognizing a selected set of one-hand Filipino Sign Language gestures. The glove measures finger bending and sends those readings to the app over Bluetooth. The app will match them to FSL-reviewed examples, display the corresponding word or phrase, and speak it in Filipino. The app interface is ready for prototype testing; the physical glove and reviewed gesture catalog are still being completed.”

## How the system is intended to work

1. The user wears a glove with five flex sensors, one for each finger.
2. An Arduino Uno reads the sensor values.
3. An ESP32-WROOM-32 sends the readings to the phone over Bluetooth Low Energy (BLE).
4. An operator adds FSL-reviewed examples and their Filipino phrases on the FSL Sign Data page.
5. While Translate is open, the app checks incoming five-finger readings against the saved examples. After a stable match, it displays and automatically speaks the predefined Filipino phrase.

**Data flow:** Flex sensors → Arduino Uno → ESP32-WROOM-32 → Bluetooth Low Energy → SENZ app → Filipino text-to-speech

The exact connection between the Arduino and ESP32, sensor value range, BLE identifiers, and message format must be confirmed with the hardware and firmware prototype.

## App features

- **Welcome and Home:** Introduces the app and opens the main screen. The welcome screen is shown on the first launch; the app saves that it has been completed.
- **Demo Mode:** Shows simulated five-finger readings so the interface can be demonstrated without the glove. Simulated readings are not FSL signs and are never used to claim a gesture was recognized.
- **Hardware Mode:** Scans for and connects to a nearby BLE sensor device, then displays incoming finger readings.
- **Calibration:** Provides open-hand and closed-hand capture steps to establish the user's sensor range before recognition.
- **FSL Sign Data:** Lets an operator enter a reviewed FSL sign label and Filipino phrase, record sensor examples from the connected glove, and add more examples for an existing sign. Data is saved locally on the phone.
- **Gesture Translation:** Runs live matching against locally saved examples while the page is open. A stable match is displayed and spoken automatically; repeat speech is also available.
- **Filipino speech:** The app's speech language is fixed to Filipino. Spoken output depends on the phone's text-to-speech engine having a Filipino voice available.
- **History:** Keeps a list of successful recognized gestures and their translations.
- **Settings:** Includes sensor mode, connected device, automatic reconnection, calibration, sensor data format, speech speed, and app information.
- **Saved app state:** Saves the recent screen, sensor mode, history, calibration values, FSL examples, and relevant preferences on the device.

## Current prototype status

The app interface, BLE connection workflow, local sign-example entry, and live matching flow are implemented. The sensor glove is not yet available for physical testing, so Bluetooth compatibility, incoming sensor readings, calibration, live detection, and speech timing still need to be verified with the prototype hardware.

The predefined FSL gesture catalog starts empty by design. The FSL Sign Data page can build a local catalog by saving reviewed labels, their agreed Filipino phrases, and real glove recordings. Live translation cannot recognize a sign until its examples have been recorded, and its matching threshold still needs validation. The app does not ship with an English or American Sign Language (ASL) catalog; operators should add only examples reviewed as FSL because the app cannot verify the language of an entry.

The current sensor design reads five flex values. Signs that depend on palm orientation, location, or movement may require additional sensors and a revised data format. The team should confirm which selected FSL signs can be distinguished reliably using the five flex sensors alone. Recorded examples are normalized using the saved calibration; if calibration changes, re-record the examples before relying on recognition.

## Technology

### Software stack

| Technology | Role in SENZ |
| --- | --- |
| Flutter | Builds the cross-platform mobile interface and app behavior. |
| Dart | Programming language used for the screens, sensor handling, recognition workflow, and saved state. |
| `flutter_reactive_ble` | Scans for BLE devices, connects to the sensor device, and receives characteristic notifications. |
| `permission_handler` and `device_info_plus` | Request the Android Bluetooth permissions required by the installed Android version. |
| `flutter_tts` | Sends recognized text to the phone's text-to-speech engine. The app configures Filipino (`fil-PH`). |
| `shared_preferences` | Stores the app's small local state snapshot, including navigation, settings, and history. |
| `cupertino_icons` | Supplies Cupertino-style icon glyphs available to the Flutter interface. |
| Flutter Material widgets | Provides the app's standard mobile controls, dialogs, themes, and navigation UI. |
| Kotlin and Gradle Kotlin DSL | Android host activity and Android build configuration. |
| Swift and Xcode project files | iOS host-app scaffold. iOS is not yet a validated release target. |

The development dependencies are `flutter_test` for widget tests and `flutter_lints` for Dart static-analysis rules.

There is no cloud service or server in the current app; the saved state is local to the device.

### Intended hardware stack

| Component | Role |
| --- | --- |
| Arduino Uno | Intended sensor reading controller. |
| ESP32-WROOM-32 | Intended wireless connection to the app. |
| Five flex sensors | Measure finger bending. |
| Bluetooth Low Energy | Planned wireless sensor data transfer. |
| Filipino text-to-speech | Speaks a recognized word or phrase using the phone's available voice. |

## Project file map

The following inventory covers the maintained app source, project configuration, platform scaffolding, assets, and tests. Build output, dependency caches, and temporary compiler files are not included.

### Root files

| File | Purpose |
| --- | --- |
| `.gitignore` | Lists generated files and local artifacts Git should ignore. |
| `.metadata` | Flutter project metadata used by Flutter tooling. |
| `.vscode/settings.json` | Workspace-specific Visual Studio Code settings. |
| `analysis_options.yaml` | Dart analyzer and lint configuration. |
| `pubspec.yaml` | App name/version, Dart constraints, Flutter assets, and direct package dependencies. |
| `pubspec.lock` | Exact resolved versions of Dart and Flutter dependencies. |
| `README.md` | Developer setup, BLE assumptions, sensor data format, recognition status, and code layout. |
| `SENZ_CLIENT_GUIDE.md` | Client-facing app overview, demonstration notes, current limitations, and this file map. |

### Flutter app source (`lib/`)

| File | Purpose |
| --- | --- |
| `lib/main.dart` | Starts Flutter, creates the shared controller, configures app themes, and saves state as the app pauses or closes. |
| `lib/app_theme.dart` | Shared SENZ colors and theme values. |
| `lib/senz_shell.dart` | Main app shell, screen stack, app navigation, first-launch welcome completion, system Back handling, and five-press Home exit behavior. |
| `lib/navigation/senz_screen.dart` | Enum naming the app's welcome, home, sensor, translation, history, and settings screens. |
| `lib/screens/welcome_screen.dart` | First-launch welcome page. |
| `lib/screens/home_screen.dart` | Main dashboard, sensor mode summary, and action to open translation. |
| `lib/screens/sensors_screen.dart` | Displays the five incoming or simulated finger sensor values. |
| `lib/screens/sign_data_screen.dart` | Form for labeling reviewed FSL signs, recording examples from the glove, saving more examples, and deleting local sign entries. |
| `lib/screens/translate_screen.dart` | Starts live translation while open and displays/speaks stable matches from the local FSL catalog. |
| `lib/screens/history_screen.dart` | Displays saved successful recognition history and history controls. |
| `lib/screens/settings_screen.dart` | Sensor mode/device settings, calibration, speech speed, About SENZ information, and license access. |
| `lib/widgets/senz_components.dart` | Reusable branding, landscape artwork, sensor/hand visualization, and bottom navigation components. |
| `lib/models/fsl_sign.dart` | Data structure and catalog for predefined FSL definitions and their labeled sensor examples. The catalog is currently empty pending review and recordings. |
| `lib/models/sensor_reading.dart` | Timestamped sensor frame and gesture-history record data types. |
| `lib/services/sensor_service.dart` | Common start/stop/readings interface shared by demo and hardware sources. |
| `lib/services/demo_sensor_service.dart` | Generates changing simulated five-finger values for UI demonstrations. |
| `lib/services/ble_config.dart` | Provisional BLE service and characteristic identifiers; these must be checked against ESP32 firmware. |
| `lib/services/bluetooth_sensor_service.dart` | BLE scanning, connection state, notifications, reconnect behavior, and device status. |
| `lib/services/sensor_data_parser.dart` | Buffers BLE text and parses five comma-separated integer readings. |
| `lib/services/sequence_sign_recognizer.dart` | Compares captured calibrated sensor sequences with configured predefined sign examples. |
| `lib/services/senz_controller.dart` | Coordinates sensor modes, BLE, calibration, capture, recognition, speech, history, settings, and app state. |
| `lib/services/senz_state_store.dart` | Reads and writes the local JSON state snapshot using shared preferences. |

### Android platform files (`android/`)

| File or group | Purpose |
| --- | --- |
| `android/settings.gradle.kts` | Configures Android Gradle plugins and included modules. |
| `android/build.gradle.kts` | Top-level Android Gradle build configuration. |
| `android/gradle.properties` | Gradle and Android build properties. |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle wrapper version and download configuration. |
| `android/app/build.gradle.kts` | App module build, package, SDK, and Flutter configuration. |
| `android/app/src/main/AndroidManifest.xml` | Main Android app metadata, permissions, and launcher activity registration. |
| `android/app/src/debug/AndroidManifest.xml` | Debug-build manifest additions. |
| `android/app/src/profile/AndroidManifest.xml` | Profile-build manifest additions. |
| `android/app/src/main/kotlin/com/example/senz_app/MainActivity.kt` | Native Android activity that hosts the Flutter app. |
| `android/app/src/main/res/drawable/launch_background.xml` | Default Android launch background. |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | Android 21+ launch background variant. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | High-density Android launcher icon. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | Medium-density Android launcher icon. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | Extra-high-density Android launcher icon. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | Extra-extra-high-density Android launcher icon. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | Extra-extra-extra-high-density Android launcher icon. |
| `android/app/src/main/res/values/styles.xml` | Light Android launch and app theme styles. |
| `android/app/src/main/res/values-night/styles.xml` | Night-mode Android launch and app theme styles. |
| `android/.gitignore` | Ignores Android-specific generated and local build files. |

### iOS platform files (`ios/`)

These files provide an Xcode host-app scaffold. They do not mean SENZ has completed iOS testing or release preparation.

| File or group | Purpose |
| --- | --- |
| `ios/Flutter/AppFrameworkInfo.plist` | Flutter framework metadata for the iOS host app. |
| `ios/Flutter/Debug.xcconfig` | Debug build settings for Flutter on iOS. |
| `ios/Flutter/Release.xcconfig` | Release build settings for Flutter on iOS. |
| `ios/Runner.xcodeproj/project.pbxproj` | Main Xcode project configuration. |
| `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | Workspace data embedded in the Xcode project. |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | Shared Xcode workspace checks. |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | Shared settings for the embedded Xcode workspace. |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | Shared build and run scheme for the iOS Runner target. |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | Main Xcode workspace data. |
| `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | Shared checks for the main Xcode workspace. |
| `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | Shared settings for the main Xcode workspace. |
| `ios/Runner/AppDelegate.swift` | Native iOS app delegate that starts the Flutter engine. |
| `ios/Runner/SceneDelegate.swift` | iOS scene lifecycle integration. |
| `ios/Runner/Info.plist` | iOS app metadata and platform permission descriptions. |
| `ios/Runner/Runner-Bridging-Header.h` | Objective-C/Swift bridging header for the Runner target. |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | Native iOS launch screen. |
| `ios/Runner/Base.lproj/Main.storyboard` | Main iOS storyboard/Flutter view host. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | Names and dimensions of iOS app icon assets. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 1024-pixel iOS app store icon. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`, `Icon-App-20x20@2x.png`, `Icon-App-20x20@3x.png` | 20-point iOS icon variants for supported screen densities. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`, `Icon-App-29x29@2x.png`, `Icon-App-29x29@3x.png` | 29-point iOS icon variants for supported screen densities. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`, `Icon-App-40x40@2x.png`, `Icon-App-40x40@3x.png` | 40-point iOS icon variants for supported screen densities. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | 60-point iOS icon at 2x density. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`, `Icon-App-76x76@2x.png` | 76-point iPad icon variants. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | 83.5-point iPad icon at 2x density. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | Names and dimensions of iOS launch images. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`, `LaunchImage@2x.png`, `LaunchImage@3x.png` | iOS launch image variants for different screen densities. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | Notes for the launch image asset set. |
| `ios/RunnerTests/RunnerTests.swift` | Native iOS Runner test target scaffold. |
| `ios/.gitignore` | Ignores iOS-specific generated and local build files. |

### Branding and Flutter test

| File | Purpose |
| --- | --- |
| `assets/images/senz_smart_sensing_logo.png` | SENZ logo used by the Flutter interface. |
| `test/widget_test.dart` | Widget test scaffold for the initial welcome-to-home flow. |

## Suggested demonstration

1. Open SENZ and show the Home screen.
2. Open **Sensor Readings** and explain that Demo Mode uses simulated values for the interface only.
3. Open **Settings** and show Hardware Mode, device connection, calibration, and **FSL Sign Data**.
4. Explain that FSL-reviewed examples are recorded on the FSL Sign Data page after the glove is connected and calibrated.
5. Open **Gesture Translation** to show live status and explain that stable matches are spoken automatically once real examples exist.
6. Show **History**, where successful live matches are saved.

When presenting the current build without the glove and recorded examples, describe live translation as implemented but awaiting hardware and FSL data validation. Do not present simulated values as recognized signs or make accuracy claims before testing with the prototype and FSL reviewers.

## Next steps before a live translation demonstration

1. Complete the glove and confirm the Arduino-to-ESP32 connection.
2. Confirm the BLE service and characteristic identifiers, five-value message order, and sensor value range with the firmware team.
3. Test scanning, connection, incoming values, disconnects, and reconnection using the physical glove.
4. Select a small set of one-hand FSL signs with FSL users or qualified reviewers.
5. Record multiple labeled examples for each sign on the FSL Sign Data page, including any agreed variants.
6. Tune the live matching threshold and stability behavior, then evaluate the results with signers who were not used to create the examples.
7. Verify Filipino text-to-speech on the target phones and confirm that a Filipino voice is installed and available.

## Limitations to communicate

- SENZ supports only selected, predefined one-hand FSL gestures once those definitions and recordings have been added.
- The app does not provide general-purpose sign language translation.
- The glove and wireless protocol have not yet been validated with physical prototype hardware.
- Recognition performance will depend on sensor calibration, the signs selected, the quality of the recorded examples, and testing across different users.
- Filipino speech playback depends on the device's text-to-speech voice support.
- iOS support is planned and is not part of the current Android prototype.
