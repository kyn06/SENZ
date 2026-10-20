import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/senz_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final SenzController controller;

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
            detail: _languageName(controller.speechLanguage),
            onTap: () => _chooseLanguage(context),
          ),
          _row(
            icon: Icons.speed_rounded,
            title: 'Speech Speed',
            detail: controller.speechSpeed,
            onTap: () => _chooseSpeed(context),
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
            detail: 'Demo gestures are not sign-language translation',
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

  Future<void> _chooseLanguage(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choice(
              sheetContext,
              'English (US)',
              'en-US',
              controller.speechLanguage,
            ),
            _choice(
              sheetContext,
              'Filipino',
              'fil-PH',
              controller.speechLanguage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    BuildContext context,
    String label,
    String value,
    String selected,
  ) => ListTile(
    title: Text(label),
    trailing: selected == value
        ? const Icon(Icons.check, color: senzGreen)
        : null,
    onTap: () {
      controller.setSpeechLanguage(value);
      Navigator.pop(context);
    },
  );

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

  void _showAbout(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: 'SENZ',
    applicationVersion: '1.0.0',
    applicationLegalese: 'Demo patterns are for interface development only. They are not validated sign-language translations.',
  );

  String _languageName(String value) =>
      value == 'fil-PH' ? 'Filipino' : 'English (US)';
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
