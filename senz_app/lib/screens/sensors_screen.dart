import 'package:flutter/material.dart';

import '../services/senz_controller.dart';
import '../widgets/senz_components.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key, required this.controller});
  final SenzController controller;

  static const readings = <(String, Color)>[
    ('Thumb', Color(0xFF4699EB)),
    ('Index Finger', Color(0xFF24925B)),
    ('Middle Finger', Color(0xFFE6C91C)),
    ('Ring Finger', Color(0xFFEF913F)),
    ('Little Finger', Color(0xFF8545C4)),
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final frame = controller.reading;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              border: Border.all(color: const Color(0xDDE5EBE2)),
              borderRadius: BorderRadius.circular(19),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D2F513D),
                  blurRadius: 20,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < readings.length; i++)
                  _readingRow(
                    readings[i].$1,
                    readings[i].$2,
                    frame != null && i < frame.values.length
                        ? frame.values[i]
                        : null,
                    i == readings.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE4EFDF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: Color(0xFF2C8550),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isDemoMode
                            ? 'Demo Sensor Data'
                            : 'Live Data',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        frame == null
                            ? (controller.isDemoMode
                                  ? 'Simulated values are starting.'
                                  : 'Waiting for a valid five-value BLE message.')
                            : frame.isSimulated
                            ? 'Simulated readings — not hardware measurements.'
                            : 'Received from ${controller.bluetooth.connectedDeviceName ?? 'BLE glove'}.',
                        style: const TextStyle(
                          color: Color(0xFF5E6C67),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (controller.bluetooth.errorMessage case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: const TextStyle(color: Color(0xFF8A3028), fontSize: 12),
              ),
            ),
        ],
      );
    },
  );

  Widget _readingRow(String name, Color color, int? value, bool last) =>
      Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFE4E9E1))),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF4EB),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.back_hand_outlined, color: color, size: 30),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value?.toString() ?? '—',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value == null ? 0 : value.clamp(0, 4095) / 4095,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5ECE2),
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
