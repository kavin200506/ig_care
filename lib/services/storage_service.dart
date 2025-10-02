import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _firstLaunchKey = 'first_launch';
  static const String _userRoleKey = 'user_role';
  
  // Check if this is the first launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }
  
  // Mark app as launched
  static Future<void> setAppLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }
  
  // Save user role (ASHA or PHC)
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }
  
  // Get saved user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }
  
  // Clear all data (for logout/reset)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
