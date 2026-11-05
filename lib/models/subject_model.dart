class SubjectModel {
  final String subjectId;
  final String name;
  final String programme;
  final int semester;
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

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: (json['subject_id'] ?? json['subjectId'] ?? '').toString(),
      // Teacher API returns `name`; student API returns `name` as well.
      // Keep compatibility with `subject_name` if an older endpoint returns it.
      name: (json['name'] ?? json['subject_name'] ?? '').toString().trim(),
      programme: (json['program'] ?? json['programme'] ?? '').toString().trim(),
      semester: _readInt(json['semester'], fallback: 0),
      threshold: _readInt(json['threshold'], fallback: 75),
      totalStudents: _readInt(
        json['total_students'] ?? json['totalStudents'],
        fallback: 0,
      ),
    );
  }
}
