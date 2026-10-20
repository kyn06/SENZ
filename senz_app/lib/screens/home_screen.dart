import 'package:flutter/material.dart';

import '../services/senz_controller.dart';
import '../widgets/senz_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onStart,
  });

  final SenzController controller;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final demo = controller.isDemoMode;
      final connected = controller.isConnected;
      final title = demo
          ? 'Demo Mode'
          : connected
          ? 'Connected'
          : controller.bluetooth.connectionMessage;
      final detail = demo
          ? 'Simulated sensor data'
          : controller.bluetooth.connectedDeviceName ?? 'No glove connected';
      final stateColor = demo
          ? const Color(0xFFB77B16)
          : connected
          ? const Color(0xFF269940)
          : const Color(0xFF7C8984);

      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
        children: [
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: stateColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    demo ? Icons.science_outlined : Icons.bluetooth_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: Color(0xFF50625E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  demo ? Icons.auto_graph_rounded : Icons.bluetooth_connected,
                  color: stateColor,
                  size: 25,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height < 720 ? 4 : 14),
          SizedBox(
            height: MediaQuery.sizeOf(context).height < 720 ? 220 : 270,
            child: GloveStage(bends: controller.handPose),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 2, bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .84),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x102F513D),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: stateColor,
                    child: Icon(
                      demo ? Icons.sync_rounded : Icons.check,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    controller.reading == null
                        ? (demo
                              ? 'Generating demo data'
                              : 'Waiting for sensors')
                        : controller.gesture,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStart,
              borderRadius: BorderRadius.circular(28),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF327B50), Color(0xFF14503C)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30204E3B),
                      blurRadius: 24,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Signing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          demo
                              ? 'Watch a simulated hand pose and hear its demo label.'
                              : 'Move your hand to translate the sensor pattern.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (controller.bluetooth.errorMessage case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
