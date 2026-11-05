import '../models/subject_model.dart';
import '../models/subject_tree_model.dart';
import 'subject_service.dart';

class SubjectTreeService {
  static Future<List<ProgrammeTreeNode>> loadTree() async {
    // The API is the source of truth. Group every subject returned by the
    // backend; do not require its ID to exist in a local curriculum file.
    final subjects = await SubjectService.getSubjects();

    final grouped = <String, Map<int, List<SubjectModel>>>{};

    for (final subject in subjects) {
      final programme = subject.programme.trim().isEmpty
          ? 'Programme not specified'
          : subject.programme.trim();
      final semester = subject.semester;

      grouped.putIfAbsent(programme, () => <int, List<SubjectModel>>{});
      grouped[programme]!.putIfAbsent(semester, () => <SubjectModel>[]);
      grouped[programme]![semester]!.add(subject);
    }

    final programmeNames = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return programmeNames.map((programmeName) {
      final semesterMap = grouped[programmeName]!;
      final semesterNumbers = semesterMap.keys.toList()..sort();

      final semesters = semesterNumbers.map((semesterNumber) {
        final semesterSubjects = semesterMap[semesterNumber]!
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return SemesterTreeNode(
          semester: semesterNumber,
          subjects: semesterSubjects
              .map((subject) => SubjectTreeNode(subject: subject))
              .toList(),
        );
      }).toList();

      return ProgrammeTreeNode(
        programme: programmeName,
        semesters: semesters,
      );
    }).toList();
  }
}
