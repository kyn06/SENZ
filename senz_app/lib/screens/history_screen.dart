import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/sensor_reading.dart';
import '../services/senz_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});
  final SenzController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final entries = controller.history;
      if (entries.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              controller.isDemoMode
                  ? 'Demo gestures will appear here as the simulated hand moves.'
                  : 'Gesture history will appear after sensor data is received.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF63716D),
              ),
            ),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.clearHistory,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Clear history'),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: Colors.white.withValues(alpha: .78),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _row(context, entries[i], i == entries.length - 1),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _row(
    BuildContext context,
    GestureRecord entry,
    bool last,
  ) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE1E7DE))),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFEDF3EA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            entry.isSimulated
                ? Icons.science_outlined
                : Icons.back_hand_outlined,
            size: 21,
            color: entry.isSimulated ? const Color(0xFFB77B16) : senzGreen,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.isSimulated ? 'Demo · ' : ''}${TimeOfDay.fromDateTime(entry.timestamp).format(context)}',
                style: const TextStyle(color: Color(0xFF596A64), fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Speak ${entry.name}',
          onPressed: () => controller.speakText(entry.name),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: senzGreen,
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
        ),
      ],
    ),
  );
}
