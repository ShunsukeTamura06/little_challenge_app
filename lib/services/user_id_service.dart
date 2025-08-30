import 'dart:math';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserIdService {
  static const _key = 'user_id';

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = _generateId();
    await prefs.setString(_key, newId);
    return newId;
  }

  static String _generateId() {
    // Generate a URL-safe random 128-bit ID
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

