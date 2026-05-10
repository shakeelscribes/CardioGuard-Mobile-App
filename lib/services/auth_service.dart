import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  static Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<User> users = [];

    if (usersJson != null) {
      final List decoded = jsonDecode(usersJson);
      users = decoded.map((e) => User.fromJson(e)).toList();
    }

    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) return 'Email already registered';

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
    );

    users.add(newUser);
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
    return null;
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return 'No account found';

    final List decoded = jsonDecode(usersJson);
    final users = decoded.map((e) => User.fromJson(e)).toList();

    final user = users.cast<User?>().firstWhere(
      (u) => u!.email.toLowerCase() == email.toLowerCase() && u.password == password,
      orElse: () => null,
    );

    if (user == null) return 'Invalid email or password';

    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    return null;
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<void> updateProfile(User updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<User> users = [];

    if (usersJson != null) {
      final List decoded = jsonDecode(usersJson);
      users = decoded.map((e) => User.fromJson(e)).toList();
    }

    final idx = users.indexWhere((u) => u.id == updatedUser.id);
    if (idx != -1) users[idx] = updatedUser;

    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
    await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
  }
}

class HistoryService {
  static String _historyKey(String userId) => 'history_$userId';

  static Future<List<PredictionRecord>> getHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_historyKey(userId));
    if (json == null) return [];
    final List decoded = jsonDecode(json);
    return decoded.map((e) => PredictionRecord.fromJson(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveRecord(String userId, PredictionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory(userId);
    history.insert(0, record);
    await prefs.setString(
      _historyKey(userId),
      jsonEncode(history.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> deleteRecord(String userId, String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory(userId);
    history.removeWhere((r) => r.id == recordId);
    await prefs.setString(
      _historyKey(userId),
      jsonEncode(history.map((r) => r.toJson()).toList()),
    );
  }
}