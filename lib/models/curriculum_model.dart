class SubjectNode {
  final String subjectId;
  final String name;

  const SubjectNode({required this.subjectId, required this.name});
}

class SemesterNode {
  final int number;
  final List<SubjectNode> subjects;

  const SemesterNode({required this.number, required this.subjects});
}

class ProgrammeNode {
  final String name;
  final List<SemesterNode> semesters;

  const ProgrammeNode({required this.name, required this.semesters});
}
