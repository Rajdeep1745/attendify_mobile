import '../models/subject_model.dart';
import '../models/subject_tree_model.dart';
import 'curriculum_service.dart';
import 'subject_service.dart';

class SubjectTreeService {
  static Future<List<ProgrammeTreeNode>> loadTree() async {
    // Load the complete curriculum from curriculum.json.
    final curriculum = await CurriculumService.loadCurriculum();

    // Load only the subjects assigned to the
    // currently logged-in teacher.
    final backendSubjects = await SubjectService.getSubjects();

    // Index the backend subjects by subjectId.
    final Map<String, SubjectModel> backendById = {
      for (final subject in backendSubjects) subject.subjectId: subject,
    };

    final List<ProgrammeTreeNode> tree = [];

    for (final programme in curriculum) {
      final List<SemesterTreeNode> semesters = [];

      for (final semester in programme.semesters) {
        final List<SubjectTreeNode> subjects = [];

        for (final curriculumSubject in semester.subjects) {
          final backendSubject = backendById[curriculumSubject.subjectId];

          // curriculum.json contains all subjects,
          // but the backend determines which subjects
          // belong to this teacher.
          if (backendSubject == null) {
            continue;
          }

          // Combine backend information with
          // curriculum information.
          final completeSubject = backendSubject.withCurriculum(
            name: curriculumSubject.name,
            programme: programme.name,
            semester: semester.number,
          );

          subjects.add(SubjectTreeNode(subject: completeSubject));
        }

        // Only include semesters containing
        // subjects assigned to the teacher.
        if (subjects.isNotEmpty) {
          semesters.add(
            SemesterTreeNode(semester: semester.number, subjects: subjects),
          );
        }
      }

      // Only include programmes containing
      // subjects assigned to the teacher.
      if (semesters.isNotEmpty) {
        tree.add(
          ProgrammeTreeNode(programme: programme.name, semesters: semesters),
        );
      }
    }

    return tree;
  }
}
