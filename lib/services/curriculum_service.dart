import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/curriculum_model.dart';

class CurriculumService {
  static Future<List<ProgrammeNode>> loadCurriculum() async {
    final jsonString = await rootBundle.loadString('assets/curriculum.json');

    final Map<String, dynamic> data = json.decode(jsonString);

    final List<ProgrammeNode> programmes = [];

    data.forEach((programmeName, programmeData) {
      final semestersJson = programmeData["semesters"] as Map<String, dynamic>;

      final List<SemesterNode> semesters = [];

      semestersJson.forEach((semesterNo, subjectsJson) {
        final subjects = (subjectsJson as List)
            .map(
              (e) => SubjectNode(
                subjectId: e["subjectId"].toString(),
                name: e["name"].toString(),
              ),
            )
            .toList();

        semesters.add(
          SemesterNode(number: int.parse(semesterNo), subjects: subjects),
        );
      });

      semesters.sort((a, b) => a.number.compareTo(b.number));

      programmes.add(ProgrammeNode(name: programmeName, semesters: semesters));
    });

    return programmes;
  }
}
