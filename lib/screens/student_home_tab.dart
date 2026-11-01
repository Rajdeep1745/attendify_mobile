import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';
import '../services/profile_service.dart';

class StudentHomeTab extends StatefulWidget {
  final List<SubjectModel> subjects;

  const StudentHomeTab({super.key, required this.subjects});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  bool isLoading = true;

  double overallAttendance = 0;

  List<dynamic> todayAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StudentHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.subjects.length != widget.subjects.length) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ---------------------------------------------------------
      // 1. GET STUDENT PROFILE
      //
      // The backend already stores the student's overall
      // attendance in students.attendance_percentage.
      // GET /api/users/me returns it as:
      //
      // attendance_percentage
      // ---------------------------------------------------------

      final profile = await ProfileService.getProfile();

      final rawOverallAttendance = profile["attendance_percentage"];

      final overall = rawOverallAttendance is num
          ? rawOverallAttendance.toDouble()
          : double.tryParse(rawOverallAttendance?.toString() ?? "") ?? 0.0;

      // ---------------------------------------------------------
      // 2. GET TODAY'S ATTENDANCE
      // ---------------------------------------------------------

      final today = DateTime.now().toIso8601String().split("T").first;

      final attendance = await AttendanceService.getStudentAttendanceByDate(
        today,
      );

      if (!mounted) return;

      setState(() {
        overallAttendance = overall;
        todayAttendance = attendance;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("STUDENT HOME ERROR: $e");

      if (!mounted) return;

      setState(() {
        // Keep today's attendance empty if the request fails.
        todayAttendance = [];

        // Don't overwrite a previously loaded value with 0
        // if this was simply a refresh failure.
        isLoading = false;
      });
    }
  }

  SubjectModel? _findSubject(String subjectId) {
    for (final subject in widget.subjects) {
      if (subject.subjectId == subjectId) {
        return subject;
      }
    }

    return null;
  }

  Color _attendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    }

    if (percentage >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _welcome(),

          const SizedBox(height: 20),

          _overallCard(),

          const SizedBox(height: 24),

          _sectionTitle("Today's Attendance"),

          const SizedBox(height: 12),

          if (isLoading)
            _loadingCard()
          else if (todayAttendance.isEmpty)
            _emptyCard()
          else
            ...todayAttendance.map(_todayTile),
        ],
      ),
    );
  }

  Widget _welcome() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Good day 👋",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 5),
        Text(
          "Here's your attendance overview.",
          style: TextStyle(color: Color(0xff666666), fontSize: 14),
        ),
      ],
    );
  }

  Widget _overallCard() {
    final color = _attendanceColor(overallAttendance);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5B45D9), Color(0xff8068F2)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overall Attendance",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${overallAttendance.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(width: 10),

              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    overallAttendance >= 75 ? "On track" : "Below target",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (overallAttendance / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${widget.subjects.length} enrolled subject${widget.subjects.length == 1 ? '' : 's'}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _todayTile(dynamic data) {
    final subjectId = data["subjectId"]?.toString() ?? "";

    final subject = _findSubject(subjectId);

    final status = data["status"]?.toString() ?? "No Class";

    final Color color;

    if (status == "Present") {
      color = Colors.green;
    } else if (status == "Absent") {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              status == "Present"
                  ? Icons.check_circle_rounded
                  : status == "Absent"
                  ? Icons.cancel_rounded
                  : Icons.remove_circle_outline_rounded,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              subject?.name.isNotEmpty == true
                  ? subject!.name
                  : "Subject $subjectId",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: Colors.deepPurple,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            "No attendance recorded today.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
