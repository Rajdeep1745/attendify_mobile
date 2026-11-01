class SubjectModel {
  // Backend identity
  final String subjectId;

  // Curriculum information
  final String name;
  final String programme;
  final int semester;

  // Backend information
  final int threshold;
  final int totalStudents;

  const SubjectModel({
    required this.subjectId,
    required this.name,
    required this.programme,
    required this.semester,
    required this.threshold,
    required this.totalStudents,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId:
          json["subject_id"]?.toString() ?? json["subjectId"]?.toString() ?? "",

      // Filled later from curriculum.json.
      name: "",
      programme: "",
      semester: 0,

      threshold: int.tryParse(json["threshold"]?.toString() ?? "") ?? 75,

      totalStudents:
          int.tryParse(
            json["total_students"]?.toString() ??
                json["totalStudents"]?.toString() ??
                "",
          ) ??
          0,
    );
  }

  SubjectModel withCurriculum({
    required String name,
    required String programme,
    required int semester,
  }) {
    return SubjectModel(
      subjectId: subjectId,
      name: name,
      programme: programme,
      semester: semester,
      threshold: threshold,
      totalStudents: totalStudents,
    );
  }
}
