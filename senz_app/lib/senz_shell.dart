import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation/senz_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sensors_screen.dart';
import 'screens/sign_data_screen.dart';
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
  List<SenzScreen> _stack = [SenzScreen.welcome];
  bool _didRestoreNavigation = false;
  int _homeBackPresses = 0;

  SenzScreen get screen => _stack.last;

  bool get _showsGlobalNavigation => switch (screen) {
    SenzScreen.home ||
    SenzScreen.sensors ||
    SenzScreen.translate ||
    SenzScreen.history => true,
    SenzScreen.welcome || SenzScreen.signData || SenzScreen.settings => false,
  };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restoreNavigation);
    _restoreNavigation();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_restoreNavigation);
    super.dispose();
  }

  void _restoreNavigation() {
    if (_didRestoreNavigation || !widget.controller.isRestored) return;
    _didRestoreNavigation = true;
    final restored = widget.controller.restoredNavigationStack
        .map(_screenFromName)
        .toList();
    if (widget.controller.welcomeCompleted) {
      restored.removeWhere((value) => value == SenzScreen.welcome);
      if (restored.isEmpty) restored.add(SenzScreen.home);
    } else if (restored.isEmpty) {
      restored.add(SenzScreen.welcome);
    }
    if (mounted) {
      setState(() => _stack = restored);
    } else {
      _stack = restored;
    }
  }

  SenzScreen _screenFromName(String name) => SenzScreen.values.firstWhere(
    (value) => value.name == name,
    orElse: () => SenzScreen.welcome,
  );

  void _saveStack() => widget.controller.updateNavigationStack(
    _stack.map((value) => value.name).toList(),
  );

  void navigateTo(SenzScreen destination) {
    if (destination == screen) return;
    _homeBackPresses = 0;
    if (screen == SenzScreen.welcome && destination == SenzScreen.home) {
      widget.controller.completeWelcome();
      setState(() => _stack = [SenzScreen.home]);
      _saveStack();
      return;
    }
    final existingIndex = _stack.lastIndexOf(destination);
    setState(() {
      if (existingIndex >= 0) {
        _stack = _stack.sublist(0, existingIndex + 1);
      } else {
        _stack = [..._stack, destination];
      }
    });
    _saveStack();
  }

  void back() {
    if (_stack.length <= 1) return;
    _homeBackPresses = 0;
    setState(() => _stack = _stack.sublist(0, _stack.length - 1));
    _saveStack();
  }

  void _handleSystemBack() {
    if (_stack.length > 1) {
      back();
      return;
    }
    if (screen != SenzScreen.home) return;

    _homeBackPresses++;
    if (_homeBackPresses >= 5) {
      SystemNavigator.pop();
      return;
    }

    final remaining = 5 - _homeBackPresses;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Press back $remaining more times to exit.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _handleSystemBack();
    },
    child: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF122622),
                    Color(0xFF1A332B),
                    Color(0xFF10211E),
                  ]
                : const [
                    Color(0xFFF5F8F1),
                    Color(0xFFEAF3E7),
                    Color(0xFFF8FAF6),
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: screen == SenzScreen.welcome
              ? WelcomeScreen(onStart: () => navigateTo(SenzScreen.home))
              : Column(
                  children: [
                    _topBar(),
                    Expanded(child: _page()),
                    if (_showsGlobalNavigation)
                      BottomNavigation(selected: screen, onSelect: navigateTo),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _topBar() {
    final title = switch (screen) {
      SenzScreen.sensors => 'Sensor Readings',
      SenzScreen.history => 'Gesture History',
      SenzScreen.signData => 'FSL Sign Data',
      SenzScreen.settings => 'Settings',
      _ => null,
    };
    final showBack = _stack.length > 1;
    final showSettings = _showsGlobalNavigation;
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
                onPressed: () => navigateTo(SenzScreen.settings),
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
      onStart: () => navigateTo(SenzScreen.translate),
    ),
    SenzScreen.sensors => SensorsScreen(controller: widget.controller),
    SenzScreen.translate => TranslateScreen(controller: widget.controller),
    SenzScreen.history => HistoryScreen(controller: widget.controller),
    SenzScreen.signData => SignDataScreen(controller: widget.controller),
    SenzScreen.settings => SettingsScreen(
      controller: widget.controller,
      onOpenSignData: () => navigateTo(SenzScreen.signData),
    ),
    SenzScreen.welcome => const SizedBox.shrink(),
  };
}
