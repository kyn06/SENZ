import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/senz_controller.dart';
import '../widgets/senz_components.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key, required this.controller});
  final SenzController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final gesture = controller.gesture;
      final hasReading = controller.reading != null;
      final isSpeaking = controller.isSpeaking;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          SizedBox(height: 250, child: GloveStage(bends: controller.handPose)),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: controller.isDemoMode
                      ? const Color(0xFFB77B16)
                      : const Color(0xFF2C8A4C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.isDemoMode
                      ? 'Demo Gesture · Simulated'
                      : hasReading
                      ? 'Gesture from sensor data'
                      : 'Waiting for sensor data',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Text(
            hasReading ? gesture : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              controller.isDemoMode
                  ? 'Predefined demo pose — not sign-language translation'
                  : 'Provisional gesture label; calibrate with the prototype',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF63716D), fontSize: 11),
            ),
          ),
          SoftCard(
            padding: const EdgeInsets.all(12),
            radius: 25,
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasReading
                        ? () => isSpeaking
                              ? controller.stopSpeaking()
                              : controller.speakGesture()
                        : null,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasReading
                              ? const [Color(0xFF3B8A58), Color(0xFF166048)]
                              : const [Color(0xFF9AA7A0), Color(0xFF82918A)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSpeaking
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children:
                              [
                                18,
                                32,
                                20,
                                42,
                                30,
                                38,
                                26,
                                40,
                                22,
                                34,
                                18,
                                29,
                              ].map((height) {
                                final barHeight = isSpeaking
                                    ? height.toDouble()
                                    : 8.0;
                                return Container(
                                  width: 3,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF24714E),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      Text(
                        isSpeaking
                            ? 'Speaking in ${controller.speechLanguage}'
                            : hasReading
                            ? 'Tap to speak'
                            : 'Waiting for a gesture',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Stop speech',
                  onPressed: controller.stopSpeaking,
                  icon: const Icon(Icons.stop_rounded),
                  color: senzDeepGreen,
                ),
              ],
            ),
          ),
          if (controller.speechError case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A3028), fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Repeat',
                  Icons.repeat_rounded,
                  hasReading ? controller.speakGesture : null,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _actionButton(
                  'Clear History',
                  Icons.delete_outline_rounded,
                  controller.clearHistory,
                  danger: true,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _actionButton(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool danger = false,
  }) => Material(
    color: Colors.white.withValues(alpha: .85),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: danger ? const Color(0xFF872D27) : senzInk,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: danger ? const Color(0xFF872D27) : senzInk,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
