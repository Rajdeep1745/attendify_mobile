import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/subject_model.dart';

class SubjectService {
  static Future<List<SubjectModel>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }
    if (role == null || role.isEmpty) {
      throw Exception('User role not found');
    }

    final String endpoint;
    if (role == 'student') {
      endpoint = '$baseUrl/subject/student';
    } else if (role == 'teacher') {
      endpoint = '$baseUrl/subject/teacher';
    } else {
      throw Exception('Unsupported user role: $role');
    }

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      throw Exception('Authentication session expired');
    }

    if (response.statusCode != 200) {
      String message = 'Failed to load subjects';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {
        // Keep the default message when the response is not JSON.
      }
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid subjects response');
    }

    // Subject names and academic details now come directly from the API.
    // Do not filter or enrich these records using curriculum.json.
    return decoded
        .whereType<Map>()
        .map(
          (item) => SubjectModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((subject) => subject.subjectId.isNotEmpty)
        .toList();
  }
}
