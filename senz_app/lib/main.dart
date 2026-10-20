import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'senz_shell.dart';
import 'services/senz_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.bottom],
  );
  runApp(const SenzApp());
}

class SenzApp extends StatefulWidget {
  const SenzApp({super.key});

  @override
  State<SenzApp> createState() => _SenzAppState();
}

class _SenzAppState extends State<SenzApp> {
  late final SenzController controller;

  @override
  void initState() {
    super.initState();
    controller = SenzController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      title: 'SENZ - Sign. Speak. Connect.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: senzCanvas,
        colorScheme: ColorScheme.fromSeed(seedColor: senzGreen),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: senzInk,
          displayColor: senzInk,
          fontFamily: 'Inter',
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: senzGreen,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: controller.themeMode,
      home: SenzShell(controller: controller),
    ),
  );
}
