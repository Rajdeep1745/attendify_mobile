import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class ProfileService {
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is Map && decoded.containsKey("data")) {
        return Map<String, dynamic>.from(decoded["data"]);
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception("Failed to load profile");
  }

  static Future<void> updateProfile({
    required String name,
    required String department,
    required int threshold,
  }) async {
    final token = await _token();

    final res = await http.patch(
      Uri.parse("$baseUrl/users/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "department": department,
        "defaultThreshold": threshold,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  // ---------------------------------------------------------
  // CHANGE PASSWORD
  // ---------------------------------------------------------

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing. Please log in again.");
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/users/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (res.statusCode == 200) return;

    throw Exception(
      data["error"]?.toString() ??
          data["message"]?.toString() ??
          "Could not change password (${res.statusCode}).",
    );
  }

  // ---------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // ---------------------------------------------------------

  static Future<String> updateAvatar(XFile image) async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing");
    }

    // Read the selected gallery image.
    final originalBytes = await image.readAsBytes();

    // Decode whatever format the gallery provided
    // and convert it to JPEG.
    final decodedImage = img.decodeImage(originalBytes);

    if (decodedImage == null) {
      throw Exception("Could not read the selected image");
    }

    final jpegBytes = Uint8List.fromList(
      img.encodeJpg(decodedImage, quality: 90),
    );

    final request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$baseUrl/users/me/avatar"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      http.MultipartFile.fromBytes(
        "avatar",
        jpegBytes,
        filename: "profile_photo.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final avatar = data["avatar"]?.toString();

      if (avatar == null || avatar.isEmpty) {
        throw Exception("Server did not return the updated profile photo");
      }

      return avatar;
    }

    try {
      final data = jsonDecode(response.body);

      throw Exception(
        data["error"]?.toString() ?? "Failed to update profile photo",
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Failed to update profile photo (${response.statusCode})",
      );
    }
  }
}
