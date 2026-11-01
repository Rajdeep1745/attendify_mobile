import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/subject_model.dart';

class SubjectService {
  // =========================================================
  // LOAD SUBJECTS
  // =========================================================

  static Future<List<SubjectModel>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    final role = prefs.getString("role");

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token not found");
    }

    if (role == null || role.isEmpty) {
      throw Exception("User role not found");
    }

    final String endpoint;

    if (role == "student") {
      endpoint = "$baseUrl/subject/student";
    } else if (role == "teacher") {
      endpoint = "$baseUrl/subject/teacher";
    } else {
      throw Exception("Unsupported user role: $role");
    }

    // ---------------------------------------------------------
    // Get subjects from backend.
    // ---------------------------------------------------------

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 401) {
      throw Exception("Authentication session expired");
    }

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);

        if (data is Map) {
          throw Exception(
            data["error"]?.toString() ?? "Failed to load subjects",
          );
        }
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
      }

      throw Exception("Failed to load subjects");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception("Invalid subjects response");
    }

    final backendSubjects = decoded
        .map((item) => SubjectModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    // ---------------------------------------------------------
    // For teachers as well as students, attach the names
    // from curriculum.json.
    // ---------------------------------------------------------

    return _attachCurriculumData(backendSubjects);
  }

  // =========================================================
  // ATTACH CURRICULUM INFORMATION
  // =========================================================

  static Future<List<SubjectModel>> _attachCurriculumData(
    List<SubjectModel> subjects,
  ) async {
    // ---------------------------------------------------------
    // Load the actual asset directly.
    //
    // We deliberately do this here instead of depending on
    // another service so there is only one place responsible
    // for converting:
    //
    // bt1_phy -> Physics
    // ---------------------------------------------------------

    final jsonString = await rootBundle.loadString("assets/curriculum.json");

    final Map<String, dynamic> curriculum = jsonDecode(jsonString);

    // ---------------------------------------------------------
    // Build:
    //
    // subjectId -> curriculum information
    // ---------------------------------------------------------

    final Map<String, Map<String, dynamic>> lookup = {};

    curriculum.forEach((programmeName, programmeData) {
      final semesters = programmeData["semesters"];

      if (semesters is! Map) {
        return;
      }

      semesters.forEach((semesterNumber, subjectsData) {
        if (subjectsData is! List) {
          return;
        }

        for (final item in subjectsData) {
          if (item is! Map) {
            continue;
          }

          final subjectId = item["subjectId"]?.toString().trim();

          final name = item["name"]?.toString().trim();

          if (subjectId == null ||
              subjectId.isEmpty ||
              name == null ||
              name.isEmpty) {
            continue;
          }

          lookup[subjectId] = {
            "name": name,
            "programme": programmeName.toString(),
            "semester": int.tryParse(semesterNumber.toString()) ?? 0,
          };
        }
      });
    });

    // ---------------------------------------------------------
    // Merge backend + curriculum.
    // ---------------------------------------------------------

    return subjects.map((subject) {
      final curriculumData = lookup[subject.subjectId.trim()];

      if (curriculumData == null) {
        return subject;
      }

      return subject.withCurriculum(
        name: curriculumData["name"] as String,

        programme: curriculumData["programme"] as String,

        semester: curriculumData["semester"] as int,
      );
    }).toList();
  }
}
