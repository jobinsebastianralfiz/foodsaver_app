import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user/user_model.dart';
import '../../../core/constants/app_constants.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferencesService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Auth Token
  Future<void> setAuthToken(String token) async {
    await prefs.setString(AppConstants.authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    return prefs.getString(AppConstants.authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await prefs.remove(AppConstants.authTokenKey);
  }

  // User Data
  Future<void> setUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(AppConstants.userDataKey, userJson);
  }

  Future<UserModel?> getUser() async {
    final userJson = prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  Future<void> clearUser() async {
    await prefs.remove(AppConstants.userDataKey);
  }

  // Onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    await prefs.setBool(AppConstants.onboardingCompletedKey, completed);
  }

  bool get isOnboardingCompleted {
    return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
