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
      final hasRecognizedSign = controller.recognizedSign != null;
      final isSpeaking = controller.isSpeaking;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          SizedBox(height: 250, child: GloveStage(bends: controller.handPose)),
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: controller.isDemoMode
                    ? const Color(0xFFB77B16)
                    : const Color(0xFF2C8A4C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.isDemoMode
                    ? 'Simulated sensor input'
                    : controller.isConnected
                    ? 'BLE sensor input'
                    : 'Waiting for sensor data',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              controller.gesture,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          if (controller.recognizedSign case final sign?)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                sign.translation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: senzDeepGreen,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              controller.hasFslSignTemplates
                  ? 'Predefined one-hand FSL vocabulary'
                  : 'FSL sign examples are not configured yet',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF63716D), fontSize: 12),
            ),
          ),
          SoftCard(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isCapturingSign
                      ? 'Recording one sign'
                      : 'One-hand sign capture',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.captureMessage ??
                      (controller.isDemoMode
                          ? 'Demo readings are simulated and will not be treated as FSL signs.'
                          : !controller.isConnected
                          ? 'Connect the BLE glove before recording a hardware sign.'
                          : !controller.isCalibrated
                          ? 'Save open-hand and closed-hand calibration in Settings before capturing a hardware sign.'
                          : 'Record one sign at a time. Only configured FSL examples can be matched.'),
                  style: const TextStyle(
                    color: Color(0xFF63716D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: controller.isCapturingSign
                        ? controller.finishSignCapture
                        : (controller.isDemoMode || controller.isConnected)
                        ? controller.beginSignCapture
                        : null,
                    icon: Icon(
                      controller.isCapturingSign
                          ? Icons.stop_rounded
                          : Icons.fiber_manual_record_rounded,
                    ),
                    label: Text(
                      controller.isCapturingSign
                          ? 'Finish & recognize'
                          : 'Start sign capture',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Current input has five finger-bend channels. Palm orientation and hand motion are not in this BLE format. The glove and any added sensors still need hardware verification.',
                  style: TextStyle(
                    color: Color(0xFF63716D),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.all(12),
            radius: 25,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: isSpeaking ? 'Stop speech' : 'Speak recognized sign',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasRecognizedSign
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
                            colors: hasRecognizedSign
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
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpeaking
                            ? 'Speaking in ${controller.speechLanguage}'
                            : hasRecognizedSign
                            ? 'Tap to speak the translation'
                            : 'Speech available after a match',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Only a recognized catalog entry can be spoken.',
                        style: TextStyle(
                          color: Color(0xFF63716D),
                          fontSize: 11,
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
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                  hasRecognizedSign ? controller.speakGesture : null,
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
