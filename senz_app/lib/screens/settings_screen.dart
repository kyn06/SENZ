import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/senz_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.onOpenSignData,
  });
  final SenzController controller;
  final VoidCallback onOpenSignData;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _section('Sensor Source', [
          _row(
            icon: controller.isDemoMode
                ? Icons.science_outlined
                : Icons.bluetooth_connected,
            title: 'Sensor Mode',
            detail: controller.isDemoMode
                ? 'Demo Mode · simulated readings'
                : 'Hardware Mode · BLE sensor data',
            onTap: () => _chooseMode(context),
          ),
        ]),
        _section('Device', [
          _row(
            icon: Icons.devices_other_rounded,
            title: 'Connected Device',
            detail: controller.isDemoMode
                ? 'Demo Mode · no hardware connected'
                : controller.bluetooth.connectedDeviceName ??
                      controller.bluetooth.connectionMessage,
            onTap: () => _showDevicePicker(context),
          ),
          _row(
            icon: Icons.autorenew_rounded,
            title: 'Auto Reconnect',
            detail: 'Retry if the connected glove drops out',
            trailing: Switch.adaptive(
              value: controller.autoReconnect,
              onChanged: controller.setAutoReconnect,
              activeTrackColor: senzLeaf,
            ),
          ),
          _row(
            icon: Icons.tune_rounded,
            title: 'Sensor Calibration',
            detail:
                controller.calibrationMessage ??
                'Open: ${controller.hasOpenHandCalibration ? 'saved' : 'needed'} · '
                    'Closed: ${controller.hasClosedHandCalibration ? 'saved' : 'needed'}',
            onTap: () => _showCalibration(context),
          ),
          _row(
            icon: Icons.data_object_rounded,
            title: 'Data Format',
            detail: controller.dataFormat,
            onTap: () => _showDataFormat(context),
          ),
        ]),
        _section('Application', [
          _row(
            icon: Icons.language_rounded,
            title: 'Speech Language',
            detail: 'Filipino',
          ),
          _row(
            icon: Icons.speed_rounded,
            title: 'Speech Speed',
            detail: controller.speechSpeed,
            onTap: () => _chooseSpeed(context),
          ),
        ]),
        _section('Recognition Data', [
          _row(
            icon: Icons.library_add_outlined,
            title: 'FSL Sign Data',
            detail: controller.fslSigns.isEmpty
                ? 'Record reviewed sign examples for translation'
                : '${controller.fslSigns.length} predefined FSL signs',
            onTap: onOpenSignData,
          ),
        ]),
        _section('About', [
          _row(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            detail: '1.0.0',
          ),
          _row(
            icon: Icons.volunteer_activism_outlined,
            title: 'About SENZ',
            detail: 'FSL vocabulary and sensor data are still being prepared',
            onTap: () => _showAbout(context),
          ),
        ]),
        if (controller.bluetooth.errorMessage case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A3028), fontSize: 12),
            ),
          ),
        if (controller.speechError case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A3028), fontSize: 12),
            ),
          ),
      ],
    ),
  );

  Widget _section(String title, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: .78),
            child: Column(children: rows),
          ),
        ),
      ],
    ),
  );

  Widget _row({
    required IconData icon,
    required String title,
    required String detail,
    Widget? trailing,
    VoidCallback? onTap,
  }) => ListTile(
    minTileHeight: 60,
    leading: Icon(icon, color: const Color(0xFF225E53), size: 21),
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      detail,
      style: const TextStyle(color: Color(0xFF596A64), fontSize: 10),
    ),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: onTap,
  );

  Future<void> _showDevicePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DeviceConnectionSheet(controller: controller),
    );
  }

  Future<void> _showCalibration(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => AlertDialog(
          title: const Text('Calibrate hand pose'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect the glove, hold all fingers open and capture. Then curl your fingers and capture the closed pose. These readings set each finger’s animation range.',
              ),
              const SizedBox(height: 14),
              Text(
                'Open pose: ${controller.hasOpenHandCalibration ? 'saved' : 'not set'}',
              ),
              Text(
                'Closed pose: ${controller.hasClosedHandCalibration ? 'saved' : 'not set'}',
              ),
              if (!controller.canCalibrateHandPose)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Switch to Hardware Mode and connect to the glove to enable capture.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: controller.canCalibrateHandPose
                  ? controller.captureOpenHandCalibration
                  : null,
              child: const Text('Capture Open'),
            ),
            TextButton(
              onPressed: controller.canCalibrateHandPose
                  ? controller.captureClosedHandCalibration
                  : null,
              child: const Text('Capture Closed'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseMode(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Demo Mode'),
              subtitle: const Text('Use changing simulated flex-sensor values'),
              onTap: () async {
                await controller.setMode(SensorMode.demo);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_searching_rounded),
              title: const Text('Hardware Mode'),
              subtitle: const Text('Scan for a nearby BLE glove'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _showDevicePicker(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseSpeed(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final speed in ['Slow', 'Normal', 'Fast'])
              ListTile(
                title: Text(speed),
                trailing: controller.speechSpeed == speed
                    ? const Icon(Icons.check, color: senzGreen)
                    : null,
                onTap: () {
                  controller.setSpeechSpeed(speed);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDataFormat(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sensor message format'),
        content: const Text(
          'The prototype parser expects five comma-separated integers in this order: Thumb, Index, Middle, Ring, Little. A newline may end each message.\n\nExample: 1820,1750,1900,1680,1800',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final screenSize = MediaQuery.sizeOf(dialogContext);
      final colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'About SENZ',
                style: Theme.of(dialogContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Close About SENZ',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        content: SizedBox(
          width: screenSize.width * .78,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenSize.height * .62),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SENZ is a finger-sensor-based system designed to translate selected Filipino Sign Language (FSL) gestures into spoken speech. It uses flex sensors to detect finger movements and a mobile application to display recognized gestures and provide spoken output.',
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _aboutSection(
                    dialogContext,
                    'Our Purpose',
                    Text(
                      'SENZ aims to support communication between people who use selected FSL gestures and people who may not understand them by converting recognized gestures into spoken words or phrases.',
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ),
                  _aboutSection(
                    dialogContext,
                    'How It Works',
                    Column(
                      children: [
                        _aboutStep(
                          dialogContext,
                          1,
                          'The user wears a glove equipped with five flex sensors.',
                        ),
                        _aboutStep(
                          dialogContext,
                          2,
                          'The Arduino Uno reads the finger-bending values.',
                        ),
                        _aboutStep(
                          dialogContext,
                          3,
                          'The ESP32 sends sensor readings to the mobile app through Bluetooth.',
                        ),
                        _aboutStep(
                          dialogContext,
                          4,
                          'The app matches a supported gesture and displays its word or phrase.',
                        ),
                        _aboutStep(
                          dialogContext,
                          5,
                          'Text-to-speech speaks the recognized output.',
                        ),
                      ],
                    ),
                  ),
                  _aboutSection(
                    dialogContext,
                    'Key Features',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutBullet(
                          dialogContext,
                          'Five-finger sensor monitoring',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Bluetooth device connection',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Predefined, one-hand gesture recognition',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Spoken output using text-to-speech',
                        ),
                        _aboutBullet(dialogContext, 'Gesture history'),
                        _aboutBullet(
                          dialogContext,
                          'User-friendly mobile interface',
                        ),
                      ],
                    ),
                  ),
                  _aboutSection(
                    dialogContext,
                    'Technology Used',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutBullet(
                          dialogContext,
                          'Flutter and Dart — mobile application',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Arduino Uno — sensor data collection',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'ESP32-WROOM-32 — wireless communication',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Five flex sensors — finger movement detection',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Bluetooth Low Energy — planned wireless data transfer',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Text-to-speech — spoken output',
                        ),
                      ],
                    ),
                  ),
                  _aboutSection(
                    dialogContext,
                    'Version Information',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutBullet(dialogContext, 'App Name: SENZ'),
                        _aboutBullet(dialogContext, 'Version: 1.0.0 (Draft)'),
                        _aboutBullet(
                          dialogContext,
                          'Platform: Android; iOS support planned',
                        ),
                        _aboutBullet(
                          dialogContext,
                          'Status: Prototype development',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Note',
                          style: Theme.of(dialogContext).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SENZ is designed for selected, predefined one-hand gestures. It is not intended to translate every FSL sign or replace a qualified sign language interpreter. Recognition performance will depend on prototype testing and calibration.',
                          style: Theme.of(dialogContext).textTheme.bodySmall
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        actions: [
          TextButton(
            onPressed: () => showLicensePage(
              context: dialogContext,
              applicationName: 'SENZ',
              applicationVersion: '1.0.0 (Draft)',
            ),
            child: const Text('Open-source licenses'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );

  Widget _aboutSection(BuildContext context, String title, Widget content) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            content,
          ],
        ),
      );

  Widget _aboutStep(BuildContext context, int number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$number',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _aboutBullet(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class DeviceConnectionSheet extends StatefulWidget {
  const DeviceConnectionSheet({super.key, required this.controller});
  final SenzController controller;

  @override
  State<DeviceConnectionSheet> createState() => _DeviceConnectionSheetState();
}

class _DeviceConnectionSheetState extends State<DeviceConnectionSheet> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.startScan());
  }

  @override
  void dispose() {
    unawaited(widget.controller.bluetooth.stopScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect a glove',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose a nearby SENZ BLE device.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Scan again',
                      onPressed: controller.isScanning
                          ? null
                          : controller.startScan,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              if (controller.isConnected)
                ListTile(
                  leading: const Icon(
                    Icons.bluetooth_connected,
                    color: senzGreen,
                  ),
                  title: Text(
                    controller.bluetooth.connectedDeviceName ??
                        'Connected glove',
                  ),
                  subtitle: Text(controller.bluetooth.connectionMessage),
                  trailing: TextButton(
                    onPressed: controller.disconnect,
                    child: const Text('Disconnect'),
                  ),
                ),
              if (controller.bluetooth.errorMessage case final error?)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Color(0xFF8A3028),
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: controller.discoveredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.isScanning)
                              const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              controller.isScanning
                                  ? 'Scanning for BLE devices…'
                                  : 'No devices found. Tap scan to try again.',
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          for (final device in controller.discoveredDevices)
                            ListTile(
                              leading: const Icon(Icons.bluetooth_rounded),
                              title: Text(
                                device.name.isEmpty
                                    ? 'Unknown BLE device'
                                    : device.name,
                              ),
                              subtitle: Text(
                                '${device.id} · ${device.rssi} dBm',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () async {
                                await controller.connect(device);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
