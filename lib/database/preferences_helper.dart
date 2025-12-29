import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // User session
  static Future<void> saveUserSession(int userId) async {
    await _preferences.setInt('user_id', userId);
  }

  static int? getUserId() {
    return _preferences.getInt('user_id');
  }

  static Future<void> clearUserSession() async {
    await _preferences.remove('user_id');
    await _preferences.remove('remember_me');
  }

  // Remember me
  static Future<void> saveRememberMe(bool remember) async {
    await _preferences.setBool('remember_me', remember);
  }

  static bool getRememberMe() {
    return _preferences.getBool('remember_me') ?? false;
  }

  // User preferences
  static Future<void> saveSortPreference(String sortBy) async {
    await _preferences.setString('sort_by', sortBy);
  }

  static String getSortPreference() {
    return _preferences.getString('sort_by') ?? 'created_at';
  }

  static Future<void> saveFilterPreference(String filter) async {
    await _preferences.setString('filter', filter);
  }

  static String getFilterPreference() {
    return _preferences.getString('filter') ?? 'all';
  }

  // Clear all preferences
  static Future<void> clearAll() async {
    await _preferences.clear();
  }
}