import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://cardiovascluar-backend.onrender.com';

  // Wake up the server
  static Future<bool> wakeUp() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> predict({
    required int gender,
    required int ageYears,
    required int height,
    required double weight,
    required int apHi,
    required int apLo,
    required int cholesterol,
    required int gluc,
    required int smoke,
    required int alco,
    required int active,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gender': gender,
          'age_years': ageYears,
          'height': height,
          'weight': weight,
          'ap_hi': apHi,
          'ap_lo': apLo,
          'cholesterol': cholesterol,
          'gluc': gluc,
          'smoke': smoke,
          'alco': alco,
          'active': active,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}