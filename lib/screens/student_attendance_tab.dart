import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';

class StudentAttendanceTab extends StatefulWidget {
  final List<SubjectModel> subjects;

  const StudentAttendanceTab({super.key, required this.subjects});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  bool isLoading = true;

  final Map<String, Map<String, dynamic>> subjectData = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void didUpdateWidget(covariant StudentAttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.subjects.length != widget.subjects.length) {
      _loadAttendance();
    }
  }

  // =========================================================
  // LOAD ALL SUBJECT ATTENDANCE
  // =========================================================

  Future<void> _loadAttendance() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      subjectData.clear();
    });

    for (final subject in widget.subjects) {
      try {
        final data = await AttendanceService.getStudentSubjectOverview(
          subject.subjectId,
        );

        if (!mounted) return;

        setState(() {
          subjectData[subject.subjectId] = data;
        });
      } catch (e) {
        debugPrint(
          "STUDENT ATTENDANCE ERROR "
          "${subject.subjectId}: $e",
        );
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // =========================================================
  // GET SUBJECT ATTENDANCE
  // =========================================================

  double _attendance(SubjectModel subject) {
    final data = subjectData[subject.subjectId];

    return double.tryParse(data?["myAttendance"]?.toString() ?? "") ?? 0;
  }

  // =========================================================
  // ATTENDANCE COLOR
  // =========================================================

  Color _attendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    }

    if (percentage >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // =========================================================
  // OPEN SUBJECT
  // =========================================================

  void _openSubject(SubjectModel subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentSubjectAttendanceScreen(subject: subject),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.deepPurple,

      onRefresh: _loadAttendance,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),

        children: [
          if (widget.subjects.isEmpty)
            _emptySubjects()
          else
            ...widget.subjects.map(_subjectCard),
        ],
      ),
    );
  }

  // =========================================================
  // SUBJECT CARD
  // =========================================================

  Widget _subjectCard(SubjectModel subject) {
    final percentage = _attendance(subject);

    final color = _attendanceColor(percentage);

    final threshold = subject.threshold;

    final aboveThreshold = percentage >= threshold;

    return GestureDetector(
      onTap: () => _openSubject(subject),

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: Colors.grey.shade100),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),

              blurRadius: 12,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: const Color(0xffEEEAFE),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: const Icon(
                    Icons.menu_book_rounded,

                    color: Colors.deepPurple,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        subject.name,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Threshold ${threshold}%",

                        style: TextStyle(
                          color: Colors.grey.shade500,

                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text(
                  "${percentage.toStringAsFixed(1)}%",

                  style: TextStyle(
                    color: color,
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    aboveThreshold ? "Above threshold" : "Below threshold",

                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),

                minHeight: 7,

                backgroundColor: Colors.grey.shade100,

                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  "Tap to view details",

                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),

                const Spacer(),

                Text(
                  "${percentage.toStringAsFixed(1)}%",

                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptySubjects() {
    return Container(
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          Icon(Icons.menu_book_outlined, color: Colors.deepPurple, size: 40),

          SizedBox(height: 12),

          Text(
            "No subjects found",

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 5),

          Text(
            "You are not enrolled in any subjects yet.",

            textAlign: TextAlign.center,

            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STUDENT SUBJECT ATTENDANCE DETAIL
// =============================================================

class StudentSubjectAttendanceScreen extends StatefulWidget {
  final SubjectModel subject;

  const StudentSubjectAttendanceScreen({super.key, required this.subject});

  @override
  State<StudentSubjectAttendanceScreen> createState() =>
      _StudentSubjectAttendanceScreenState();
}

class _StudentSubjectAttendanceScreenState
    extends State<StudentSubjectAttendanceScreen> {
  bool isLoading = true;

  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();

    _load();
  }

  // =========================================================
  // LOAD SUBJECT REPORT
  // =========================================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AttendanceService.getStudentSubjectReport(
        widget.subject.subjectId,
      );

      if (!mounted) return;

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("SUBJECT ATTENDANCE DETAIL ERROR: $e");

      if (!mounted) return;

      setState(() {
        data = {};
        isLoading = false;
      });
    }
  }

  // =========================================================
  // SAFE NUMBER
  // =========================================================

  double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String _formatDate(String value) {
    if (value.isEmpty) {
      return "-";
    }

    try {
      final date = DateTime.parse(value);

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      return "${date.day.toString().padLeft(2, '0')} "
          "${months[date.month - 1]} "
          "${date.year}";
    } catch (_) {
      return value;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        title: Text(
          widget.subject.name.isEmpty ? "Attendance" : widget.subject.name,
        ),

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        elevation: 0,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              color: Colors.deepPurple,

              onRefresh: _load,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                children: [
                  _attendanceHeader(),

                  const SizedBox(height: 18),

                  _statisticsCard(),

                  const SizedBox(height: 22),

                  const Text(
                    "Attendance History",

                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _history(),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // ATTENDANCE HEADER
  // =========================================================

  Widget _attendanceHeader() {
    final percentage = _double(data["myAttendance"]);

    final threshold = _int(data["threshold"]);

    final above = percentage >= threshold;

    // final color = above ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xff5B45D9), Color(0xff8068F2)],
        ),

        borderRadius: BorderRadius.circular(25),

        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.18),

            blurRadius: 20,

            offset: const Offset(0, 9),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            widget.subject.name.isEmpty
                ? "Subject Attendance"
                : widget.subject.name,

            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 8),

          Text(
            "${percentage.toStringAsFixed(1)}%",

            style: const TextStyle(
              color: Colors.white,

              fontSize: 42,

              fontWeight: FontWeight.bold,

              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Icon(
                above ? Icons.check_circle_rounded : Icons.warning_rounded,

                color: Colors.white,

                size: 18,
              ),

              const SizedBox(width: 7),

              Text(
                above ? "Above threshold" : "Below threshold",

                style: const TextStyle(
                  color: Colors.white,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "Required attendance: $threshold%",

            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATISTICS
  // =========================================================

  Widget _statisticsCard() {
    final total = _int(data["totalClasses"]);

    final attended = _int(data["attendedClasses"]);

    final absent = (total - attended).clamp(0, total);

    final subjectAverage = _double(data["subjectAverage"]);

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statItem(
                  "Classes",
                  total.toString(),
                  Icons.calendar_month_rounded,
                  Colors.deepPurple,
                ),
              ),

              Expanded(
                child: _statItem(
                  "Present",
                  attended.toString(),
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),

              Expanded(
                child: _statItem(
                  "Absent",
                  absent.toString(),
                  Icons.cancel_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Divider(color: Colors.grey.shade200, height: 1),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.groups_rounded,

                color: Colors.deepPurple,

                size: 20,
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  "Subject average",

                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              Text(
                "${subjectAverage.toStringAsFixed(1)}%",

                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),

        const SizedBox(height: 7),

        Text(
          value,

          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          label,

          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  // =========================================================
  // HISTORY
  // =========================================================

  Widget _history() {
    final recent = data["recentAttendance"];

    if (recent is! List || recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),
        ),

        child: const Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.grey, size: 34),

            SizedBox(height: 9),

            Text(
              "No attendance history available.",

              textAlign: TextAlign.center,

              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recent.map<Widget>((item) {
        final status = item["status"]?.toString() ?? "Unknown";

        final rawDate = item["date"]?.toString() ?? "";

        final date = _formatDate(rawDate);

        final present = status == "Present";

        final absent = status == "Absent";

        final color = present
            ? Colors.green
            : absent
            ? Colors.red
            : Colors.grey;

        final icon = present
            ? Icons.check_circle_rounded
            : absent
            ? Icons.cancel_rounded
            : Icons.remove_circle_outline_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 9),

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(17),

            border: Border.all(color: Colors.grey.shade100),
          ),

          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  date,

                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              Text(
                status,

                style: TextStyle(
                  color: color,

                  fontWeight: FontWeight.bold,

                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
