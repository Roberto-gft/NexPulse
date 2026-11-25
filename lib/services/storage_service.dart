import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/workout_session.dart';

class StorageService {
  static const String _userKey = 'nexpulse_user_data';
  static const String _loggedInKey = 'nexpulse_is_logged_in';
  static const String _workoutsKey = 'nexpulse_workouts_list';

  static String hashPassword(String plainPassword) {
    final bytes = utf8.encode(plainPassword);
    return sha256.convert(bytes).toString();
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePassword(String newPlainPassword) async {
    final currentUser = await getUser();
    if (currentUser == null) return;
    final updated = currentUser.copyWith(
      passwordHash: hashPassword(newPlainPassword),
    );
    await saveUser(updated);
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> saveWorkout(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getWorkouts();
    existing.insert(0, session);
    final encoded = existing.map((w) => w.toJson()).toList();
    await prefs.setString(_workoutsKey, jsonEncode(encoded));
  }

  Future<List<WorkoutSession>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workoutsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => WorkoutSession.fromJson(
          item is String ? item : jsonEncode(item),
        ),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }
}