// lib/services/user_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // A key to store the user ID in shared preferences.
  static const String _userIdKey = 'user_id';

  // Method to get the stored user ID.
  // It returns null if no ID is found.
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Method to save the user ID.
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }
}
