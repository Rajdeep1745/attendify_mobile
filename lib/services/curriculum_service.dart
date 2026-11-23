import '../models/curriculum_model.dart';
import 'subject_service.dart';

class CurriculumService {
  static Future<List<ProgrammeNode>> loadCurriculum() async {
    final subjects = await SubjectService.getSubjects();
    final grouped = <String, Map<int, List<SubjectNode>>>{};
    for (final subject in subjects) {
      final semesters = grouped.putIfAbsent(subject.programme, () => {});
      semesters
          .putIfAbsent(subject.semester, () => [])
          .add(SubjectNode(subjectId: subject.subjectId, name: subject.name));
    }
    return grouped.entries
        .map(
          (programme) => ProgrammeNode(
            name: programme.key,
            semesters:
                programme.value.entries
                    .map(
                      (semester) => SemesterNode(
                        number: semester.key,
                        subjects: semester.value,
                      ),
                    )
                    .toList()
                  ..sort((a, b) => a.number.compareTo(b.number)),
          ),
        )
        .toList();
  }
}
