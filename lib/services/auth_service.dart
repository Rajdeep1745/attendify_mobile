import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AuthService {
  // =========================================================
  // LOGIN
  // =========================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic> data;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        } else {
          return {"success": false, "message": "Invalid server response"};
        }
      } catch (_) {
        return {
          "success": false,
          "message": "Invalid response from server (${response.statusCode})",
        };
      }

      if (response.statusCode == 200) {
        if (data["user"] is! Map || data["token"] == null) {
          return {
            "success": false,
            "message": "Invalid login response from server",
          };
        }

        final prefs = await SharedPreferences.getInstance();

        final user = Map<String, dynamic>.from(data["user"]);

        final token = data["token"]?.toString() ?? "";

        final role = user["role"]?.toString().toLowerCase();

        if (token.isEmpty) {
          return {
            "success": false,
            "message": "Server did not return a login token",
          };
        }

        if (role != "student" && role != "teacher") {
          return {"success": false, "message": "Invalid user role"};
        }

        await prefs.setString("token", token);

        await prefs.setString("name", user["name"]?.toString() ?? "");

        await prefs.setString("role", role!);

        await prefs.setString("user", jsonEncode(user));

        return {"success": true, "data": data};
      }

      return {
        "success": false,
        "message":
            data["error"]?.toString() ??
            "Login failed (${response.statusCode})",
      };
    } on TimeoutException {
      return {
        "success": false,
        "message":
            "Unable to reach the server. "
            "Check that the backend is running and "
            "your phone is connected to the same Wi-Fi.",
      };
    } catch (_) {
      return {"success": false, "message": "Unable to connect to the server."};
    }
  }

  // =========================================================
  // VALIDATE EXISTING LOGIN SESSION
  // =========================================================

  static Future<Map<String, dynamic>?> validateSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    // Keep the last known user so the app can still open if the
    // backend is temporarily unreachable. SharedPreferences survives
    // app closure/restart; only an explicitly invalid token clears it.
    Map<String, dynamic>? cachedUser;
    final cachedJson = prefs.getString("user");
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map) {
          cachedUser = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        cachedUser = null;
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/users/me"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        Map<String, dynamic> user;
        if (decoded is Map && decoded["data"] is Map) {
          user = Map<String, dynamic>.from(decoded["data"]);
        } else if (decoded is Map) {
          user = Map<String, dynamic>.from(decoded);
        } else {
          return cachedUser;
        }

        final role = user["role"]?.toString().toLowerCase();
        if (role != "student" && role != "teacher") {
          // A malformed response shouldn't silently log the user out.
          return cachedUser;
        }

        await prefs.setString("role", role!);
        await prefs.setString("name", user["name"]?.toString() ?? "");
        await prefs.setString("user", jsonEncode(user));
        return user;
      }

      // A 401/403 means the server has explicitly rejected the token.
      if (response.statusCode == 401 || response.statusCode == 403) {
        await clearSession();
        return null;
      }

      // Server errors or a missing route aren't proof that the token
      // is invalid. Keep the saved session and allow a retry later.
      return cachedUser;
    } catch (_) {
      // No network / timeout: preserve login and use cached user data.
      return cachedUser;
    }
  }

  // =========================================================
  // CLEAR SESSION
  // =========================================================

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("name");
    await prefs.remove("role");
    await prefs.remove("user");
  }

  // =========================================================
  // SIGNUP
  // =========================================================

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String department,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'department': department,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"success": true, "data": data};
    }

    return {"success": false, "message": data["error"] ?? "Signup failed"};
  }
}
