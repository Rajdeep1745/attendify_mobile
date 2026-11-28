import 'api_client.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class ProfileService {
  static Future<Uint8List> _prepareAvatar(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw Exception('The selected photo is empty');

    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
      if (decoded != null) decoded = img.bakeOrientation(decoded);
    } catch (_) {
      // The native gallery can return formats the Dart decoder cannot read.
    }

    if (decoded == null) {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          final frame = await codec.getNextFrame();
          final frameImage = frame.image;
          try {
            final rgba = await frameImage.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            if (rgba == null) {
              throw const FormatException('Image has no pixels');
            }
            decoded = img.Image.fromBytes(
              width: frameImage.width,
              height: frameImage.height,
              bytes: rgba.buffer,
              bytesOffset: rgba.offsetInBytes,
              order: img.ChannelOrder.rgba,
            );
          } finally {
            frameImage.dispose();
          }
        } finally {
          codec.dispose();
        }
      } catch (_) {
        throw Exception(
          'This photo format cannot be opened. Choose another photo.',
        );
      }
    }

    final longestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    if (longestSide > 600) {
      decoded = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: 600)
          : img.copyResize(decoded, height: 600);
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 82));
  }

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _token();

    final res = await ApiClient.get(
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
    required String institution,
    int? threshold,
  }) async {
    final token = await _token();
    final body = <String, Object>{
      "name": name,
      "department": department,
      "institution": institution,
    };
    if (threshold != null) body["defaultThreshold"] = threshold;

    final res = await ApiClient.patch(
      Uri.parse("$baseUrl/users/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) return;

    final error = jsonDecode(res.body);
    throw Exception(error["error"]?.toString() ?? "Update failed");
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

    final res = await ApiClient.patch(
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

    final uploadBytes = await _prepareAvatar(image);

    final request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$baseUrl/users/me/avatar"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      http.MultipartFile.fromBytes(
        "avatar",
        uploadBytes,
        filename: 'profile_photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final avatar = data["avatar"]?.toString();

      if (avatar == null || avatar.isEmpty) {
        throw Exception("Server did not return the updated profile photo");
      }

      // Read the saved value back so the profile never reports success for an
      // image that the API did not persist.
      final savedProfile = await getProfile();
      final savedAvatar = savedProfile["avatar"]?.toString();
      if (savedAvatar == null || savedAvatar.isEmpty) {
        throw Exception("The server did not save the profile photo");
      }

      return savedAvatar;
    }

    String? message;
    try {
      final data = jsonDecode(response.body);
      message = data["error"]?.toString();
    } catch (_) {}

    if (response.statusCode == 403) {
      throw Exception(
        message ?? 'This account is not allowed to upload a profile photo.',
      );
    }

    throw Exception(
      message ?? "Failed to update profile photo (${response.statusCode})",
    );
  }
}
