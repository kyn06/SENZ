import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/fsl_sign.dart';
import '../services/senz_controller.dart';
import '../widgets/senz_components.dart';

class SignDataScreen extends StatefulWidget {
  const SignDataScreen({super.key, required this.controller});

  final SenzController controller;

  @override
  State<SignDataScreen> createState() => _SignDataScreenState();
}

class _SignDataScreenState extends State<SignDataScreen> {
  final _signName = TextEditingController();
  final _translation = TextEditingController();

  @override
  void dispose() {
    _signName.dispose();
    _translation.dispose();
    super.dispose();
  }

  void _saveSample() {
    final error = widget.controller.saveTrainingSample(
      displayName: _signName.text,
      translation: _translation.text,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? 'FSL example saved on this device.')),
      );
  }

  Future<void> _confirmDelete(FslSignDefinition sign) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this sign?'),
        content: Text(
          '“${sign.displayName}” and its ${sign.examples.length} recorded example(s) will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) widget.controller.deleteFslSign(sign.id);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(16),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Build the predefined FSL vocabulary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Add a sign name, the Filipino word or phrase to speak, and a real sensor recording. Only add signs reviewed by an FSL signer. SENZ does not verify that a label is a valid FSL sign.',
                  style: TextStyle(
                    color: Color(0xFF63716D),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                _statusLine(
                  context,
                  Icons.bluetooth_rounded,
                  controller.isDemoMode
                      ? 'Switch to Hardware Mode to record real examples.'
                      : controller.isConnected
                      ? 'BLE glove connected'
                      : 'Connect the BLE glove in Settings',
                ),
                const SizedBox(height: 5),
                _statusLine(
                  context,
                  Icons.tune_rounded,
                  controller.isCalibrated
                      ? 'Open-hand and closed-hand calibration ready'
                      : 'Calibrate open and closed hand poses in Settings',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.all(15),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record a sign example',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Record each sign several times. Reuse the same sign name and Filipino phrase to add another example for that sign.',
                  style: TextStyle(
                    color: Color(0xFF63716D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _signName,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'FSL sign name',
                    hintText: 'Use the reviewer-approved sign label',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _translation,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Filipino word or phrase to speak',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7EF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    controller.isCapturingTrainingSample
                        ? 'Recording ${controller.trainingFrameCount} sensor frames. Perform one sign now, then stop.'
                        : controller.trainingMessage ??
                              (controller.hasPendingTrainingSample
                                  ? '${controller.trainingFrameCount} frames ready to save.'
                                  : 'Start recording just before performing one sign. Stop just after completing it.'),
                    style: const TextStyle(
                      color: Color(0xFF425852),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: controller.isCapturingTrainingSample
                              ? controller.stopTrainingSample
                              : controller.canRecordFslSample
                              ? controller.beginTrainingSample
                              : null,
                          icon: Icon(
                            controller.isCapturingTrainingSample
                                ? Icons.stop_rounded
                                : Icons.fiber_manual_record_rounded,
                          ),
                          label: Text(
                            controller.isCapturingTrainingSample
                                ? 'Stop recording'
                                : 'Record example',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: controller.hasPendingTrainingSample
                              ? _saveSample
                              : null,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save example'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved FSL signs',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${controller.fslSigns.length}',
                style: const TextStyle(
                  color: Color(0xFF63716D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.fslSigns.isEmpty)
            SoftCard(
              padding: const EdgeInsets.all(16),
              radius: 16,
              child: const Text(
                'No sign examples saved yet. Recorded examples will be stored locally on this device.',
                style: TextStyle(
                  color: Color(0xFF63716D),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            )
          else
            ...controller.fslSigns.map(
              (sign) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  radius: 16,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDCEBD8),
                      child: Icon(
                        Icons.front_hand_outlined,
                        color: senzDeepGreen,
                      ),
                    ),
                    title: Text(
                      sign.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${sign.translation} · ${sign.examples.length} example(s)',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete ${sign.displayName}',
                      onPressed: () => _confirmDelete(sign),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: const Color(0xFF872D27),
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Training examples and translations stay on this phone. Recognition quality must be validated with FSL reviewers and real glove recordings before using this as a communication aid.',
            style: TextStyle(
              color: Color(0xFF63716D),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      );
    },
  );

  Widget _statusLine(BuildContext context, IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF425852)),
        ),
      ),
    ],
  );
}
