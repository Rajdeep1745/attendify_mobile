import 'subject_model.dart';

class SubjectTreeNode {
  final SubjectModel subject;

  const SubjectTreeNode({required this.subject});

  String get subjectId => subject.subjectId;

  String get name => subject.name;
}

class SemesterTreeNode {
  final int semester;
  final List<SubjectTreeNode> subjects;

  const SemesterTreeNode({required this.semester, required this.subjects});
}

class ProgrammeTreeNode {
  final String programme;
  final List<SemesterTreeNode> semesters;

  const ProgrammeTreeNode({required this.programme, required this.semesters});
}
