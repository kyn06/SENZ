import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/senz_controller.dart';
import '../widgets/senz_components.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key, required this.controller});

  final SenzController controller;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.startLiveTranslation();
    });
  }

  @override
  void dispose() {
    widget.controller.stopLiveTranslation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final hasRecognizedSign = controller.recognizedSign != null;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          SizedBox(height: 230, child: GloveStage(bends: controller.handPose)),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    controller.isLiveTranslationEnabled &&
                        !controller.isDemoMode &&
                        controller.isConnected &&
                        controller.isCalibrated &&
                        controller.hasFslSignTemplates
                    ? const Color(0xFF2C8A4C)
                    : const Color(0xFFB77B16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.isDemoMode
                    ? 'Demo input · translation paused'
                    : controller.isConnected
                    ? 'BLE sensor input'
                    : 'Waiting for BLE sensor',
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
              hasRecognizedSign
                  ? controller.recognizedSign!.displayName
                  : 'Listening',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
          ),
          if (controller.recognizedSign case final sign?)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                sign.translation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: senzDeepGreen,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 16),
            child: Text(
              controller.liveTranslationMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF63716D),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          SoftCard(
            padding: const EdgeInsets.all(15),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real-time translation',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The app checks incoming readings continuously and speaks a supported Filipino translation after the match is stable. Perform one sign at a time and return to a neutral pose between signs.',
                  style: TextStyle(
                    color: Color(0xFF63716D),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.hasFslSignTemplates
                      ? '${controller.fslSigns.length} local predefined FSL sign(s) available'
                      : 'No FSL examples yet. Add reviewed examples from Settings → FSL Sign Data.',
                  style: const TextStyle(
                    color: Color(0xFF425852),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Prototype recognition is experimental. Sign definitions, thresholds, and sensor behavior need validation with FSL reviewers and the physical glove.',
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
                IconButton.filled(
                  tooltip: hasRecognizedSign
                      ? 'Repeat Filipino translation'
                      : 'Translation will be available after a match',
                  onPressed: hasRecognizedSign ? controller.speakGesture : null,
                  icon: const Icon(Icons.repeat_rounded),
                  constraints: const BoxConstraints.tightFor(
                    width: 52,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isSpeaking
                            ? 'Speaking in Filipino'
                            : hasRecognizedSign
                            ? 'Translation spoken automatically'
                            : 'Filipino speech is ready',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap repeat to hear the latest recognized phrase again.',
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
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
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
        ],
      );
    },
  );
}
