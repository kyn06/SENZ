import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small, local-only store for the app's last screen, settings and history.
class SenzStateStore {
  static const _key = 'senz.app_state.v1';

  Future<Map<String, dynamic>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Ignore a corrupt or outdated snapshot and start with defaults.
    }
    return {};
  }

  Future<void> save(Map<String, Object?> state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(state));
  }
}
