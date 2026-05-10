import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SupabaseConfig {
  static const String url = 'https://lpuxklrgvftvhlnhyero.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwdXhrbHJndmZ0dmhsbmh5ZXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0ODU1MzMsImV4cCI6MjA5MDA2MTUzM30.-9UBCgJCcCGHBzFDp8mYFUehfvWAyNC-VAxLoQc5TXI';
  static const String webClientId = '596138886171-ppevclcdqgtvs37g32srs07brl1g0fqb.apps.googleusercontent.com';
}

class SupabaseAuthService {
  static final _client = Supabase.instance.client;

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  static Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // trigger picks this up → creates profiles row
      );
      if (response.user == null) return 'Signup failed';
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return 'Sign in aborted by user';
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) throw 'No Access Token found.';
      if (idToken == null) throw 'No ID Token found.';

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return 'Invalid email or password';
    }
  }

  static Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.webClientId,
      );
      await googleSignIn.signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // ─────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────

  /// Sends a password reset email to the user
  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'cardioguard://reset-callback/',
      );
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates the user's password (called after they click the email link)
  static Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // PROFILE — read
  // ─────────────────────────────────────────

  /// One-time fetch — use when you need profile data once
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Real-time stream — subscribe in any screen to auto-update on changes
  /// Emits whenever name, avatar, or any profile field changes
  static Stream<Map<String, dynamic>?> profileStream() {
    final user = _client.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  // ─────────────────────────────────────────
  // PROFILE — update
  // ─────────────────────────────────────────

  /// Updates name, age, gender, height, weight
  /// Stream auto-pushes changes to all listening screens
  static Future<String?> updateProfile({
    required String name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 'User not logged in';
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
      });
      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // AVATAR — upload / remove
  // ─────────────────────────────────────────

  /// Uploads image to Supabase Storage (avatars bucket)
  /// Saves public URL to profiles.avatar_url
  /// Stream auto-updates avatar everywhere
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$fileExt';

      // Upload — upsert:true overwrites existing avatar
      await _client.storage.from('avatars').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL with cache-busting timestamp
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      final urlWithBust = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Save URL to profiles — stream will push to all screens instantly
      await _client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': urlWithBust,
      });

      return urlWithBust;
    } catch (e) {
      return null;
    }
  }

  /// Removes avatar — sets avatar_url to null in profiles
  /// Stream auto-clears avatar everywhere, falls back to letter
  static Future<String?> removeAvatar() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 'User not logged in';

      // Delete file from storage
      final possibleExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      for (final ext in possibleExtensions) {
        try {
          await _client.storage
              .from('avatars')
              .remove(['${user.id}/avatar.$ext']);
        } catch (_) {
          // Ignore — file with this extension might not exist
        }
      }

      // Clear URL from profiles — stream pushes null to all screens
      await _client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': null,
      });

      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }
}

class SupabaseHistoryService {
  static final _client = Supabase.instance.client;

  // ─────────────────────────────────────────
  // PREDICTIONS
  // ─────────────────────────────────────────

  /// Saves a new prediction record for the current user
  static Future<void> savePrediction(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('predictions').insert({
      'user_id': user.id,
      ...data,
    });
  }

  /// Returns all predictions for current user, newest first
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      final response = await _client
          .from('predictions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Deletes a single prediction by ID
  static Future<void> deletePrediction(String id) async {
    await _client.from('predictions').delete().eq('id', id);
  }
}