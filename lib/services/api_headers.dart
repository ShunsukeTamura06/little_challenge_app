import 'package:little_challenge_app/services/user_id_service.dart';

class ApiHeaders {
  static Future<Map<String, String>> jsonHeaders() async {
    final userId = await UserIdService.getUserId();
    return {
      'Content-Type': 'application/json',
      'X-User-Id': userId,
    };
  }

  static Future<Map<String, String>> baseHeaders() async {
    final userId = await UserIdService.getUserId();
    return {
      'X-User-Id': userId,
    };
  }
}

