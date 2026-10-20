import 'package:flutter/material.dart';

import 'navigation/senz_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sensors_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/senz_controller.dart';
import 'widgets/senz_components.dart';

class SenzShell extends StatefulWidget {
  const SenzShell({super.key, required this.controller});
  final SenzController controller;

  @override
  State<SenzShell> createState() => _SenzShellState();
}

class _SenzShellState extends State<SenzShell> {
  SenzScreen screen = SenzScreen.welcome;
  SenzScreen previous = SenzScreen.home;

  void openSettings() => setState(() {
    previous = screen;
    screen = SenzScreen.settings;
  });

  void back() => setState(() => screen = previous);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF122622), Color(0xFF1A332B), Color(0xFF10211E)]
              : const [Color(0xFFF5F8F1), Color(0xFFEAF3E7), Color(0xFFF8FAF6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: screen == SenzScreen.welcome
            ? WelcomeScreen(
                onStart: () => setState(() => screen = SenzScreen.home),
              )
            : Column(
                children: [
                  _topBar(),
                  Expanded(child: _page()),
                  if (screen != SenzScreen.settings)
                    BottomNavigation(
                      selected: screen,
                      onSelect: (value) => setState(() => screen = value),
                    ),
                ],
              ),
      ),
    ),
  );

  Widget _topBar() {
    final title = switch (screen) {
      SenzScreen.sensors => 'Sensor Readings',
      SenzScreen.history => 'Gesture History',
      SenzScreen.settings => 'Settings',
      _ => null,
    };
    final showBack =
        screen == SenzScreen.history || screen == SenzScreen.settings;
    final showSettings = title == null;
    return SizedBox(
      height: 61,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                tooltip: 'Go back',
                onPressed: back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                color: const Color(0xFF163C37),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
              )
            else
              const SizedBox(width: 44),
            Expanded(
              child: title == null
                  ? const Center(child: Brand(compact: true))
                  : Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                      ),
                    ),
            ),
            if (showSettings)
              IconButton(
                tooltip: 'Open settings',
                onPressed: openSettings,
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: const Color(0xFF163C37),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _page() => switch (screen) {
    SenzScreen.home => HomeScreen(
      controller: widget.controller,
      onStart: () => setState(() => screen = SenzScreen.translate),
    ),
    SenzScreen.sensors => SensorsScreen(controller: widget.controller),
    SenzScreen.translate => TranslateScreen(controller: widget.controller),
    SenzScreen.history => HistoryScreen(controller: widget.controller),
    SenzScreen.settings => SettingsScreen(controller: widget.controller),
    SenzScreen.welcome => const SizedBox.shrink(),
  };
}
