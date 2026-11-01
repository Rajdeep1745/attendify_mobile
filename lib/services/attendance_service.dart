import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AttendanceService {
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> uploadAttendance(
    String imagePath,
    String subjectId,
  ) async {
    final token = await _token();

    final today = DateTime.now().toIso8601String().split("T").first;

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/attendance/$subjectId/face"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.fields["date"] = today;

    request.files.add(
      await http.MultipartFile.fromPath(
        "faceMedia",
        imagePath,
        filename: "attendance.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
    );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    final data = jsonDecode(body);

    if (response.statusCode == 200) {
      data["subjectId"] = subjectId;
      data["date"] = today;

      return Map<String, dynamic>.from(data);
    }

    throw Exception(data["error"] ?? "Upload failed");
  }

  static Future<Map<String, dynamic>> getStats(String subjectId) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/attendance/$subjectId/stats"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }

    throw Exception("Failed to load stats");
  }

  static Future<List<dynamic>> getGraph(String subjectId) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/attendance/$subjectId/graph"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Failed");
  }

  static Future<List<dynamic>> getFrequentAbsentees(String subjectId) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/attendance/$subjectId/frequent-absentees"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Failed");
  }

  static Future<List<dynamic>> getDailyAttendance(
    String subjectId,
    String date,
  ) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/attendance/$subjectId/daily?date=$date"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Failed to load daily attendance");
  }

  static Future<void> saveOverrides(
    String subjectId,
    String date,
    List attendance,
  ) async {
    final token = await _token();

    final overrides = attendance.map((student) {
      return {
        "student_id": student["student_id"],
        "present": student["present"],
      };
    }).toList();

    final res = await http.patch(
      Uri.parse("$baseUrl/attendance/$subjectId/override"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"date": date, "overrides": overrides}),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  static Future<void> markManualAttendance(
    String subjectId,
    List<Map<String, dynamic>> records,
  ) async {
    final token = await _token();

    final today = DateTime.now().toIso8601String().split("T").first;

    final res = await http.post(
      Uri.parse("$baseUrl/attendance/$subjectId/mark"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"date": today, "attendance": records}),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);

      throw Exception(data["error"] ?? "Failed to submit attendance");
    }
  }

  static Future<List<dynamic>> fetchStudents(String subjectId) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/students/$subjectId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Failed to fetch students");
  }

  static Future<int> updateThreshold(String subjectId, int threshold) async {
    final token = await _token();

    final res = await http.patch(
      Uri.parse("$baseUrl/subject/$subjectId/threshold"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"threshold": threshold}),
    );

    if (res.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(res.body));

      return int.tryParse(data["threshold"]?.toString() ?? "") ?? threshold;
    }

    final data = jsonDecode(res.body);

    throw Exception(data["error"] ?? "Failed to update threshold");
  }

  // =========================================================
  // STUDENT ATTENDANCE
  // =========================================================

  static Future<List<dynamic>> getStudentAttendanceByDate(String date) async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/attendance/student?date=$date"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data is List) {
        return data;
      }

      throw Exception("Invalid student attendance response");
    }

    try {
      final data = jsonDecode(res.body);

      throw Exception(
        data["error"]?.toString() ?? "Failed to load student attendance",
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception("Failed to load student attendance");
    }
  }

  // =========================================================
  // STUDENT SUBJECT OVERVIEW
  // =========================================================

  static Future<Map<String, dynamic>> getStudentSubjectOverview(
    String subjectId,
  ) async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/subject/$subjectId/overview"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    if (data is Map) {
      throw Exception(
        data["error"]?.toString() ?? "Failed to load subject overview",
      );
    }

    throw Exception("Failed to load subject overview");
  }

  // =========================================================
  // STUDENT SUBJECT REPORT
  // =========================================================

  static Future<Map<String, dynamic>> getStudentSubjectReport(
    String subjectId,
  ) async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/subject/$subjectId/reports"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    if (data is Map) {
      throw Exception(
        data["error"]?.toString() ?? "Failed to load subject report",
      );
    }

    throw Exception("Failed to load subject report");
  }
}
