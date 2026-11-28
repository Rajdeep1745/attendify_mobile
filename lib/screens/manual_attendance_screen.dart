import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../widgets/app_loading_view.dart';

class ManualAttendanceScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const ManualAttendanceScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  List students = [];
  final date = DateTime.now().toIso8601String().split("T").first;

  Map<String, bool> attendanceMap = {};

  bool isLoading = true;
  bool isSubmitting = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final loadingTimer = MinimumLoadingTimer();
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final data = await AttendanceService.fetchStudents(widget.subjectId);
      final daily = await AttendanceService.getDailyAttendance(
        widget.subjectId,
        date,
      );
      final existing = {
        for (final row in daily) row['studentId']: row['present'] == true,
      };

      await loadingTimer.wait();
      if (!mounted) return;

      setState(() {
        students = data;
        attendanceMap = {
          for (final student in data)
            student['id'].toString(): existing[student['id']] ?? false,
        };
        isLoading = false;
      });
    } catch (e) {
      await loadingTimer.wait();
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = 'Could not load the student roster. Please try again.';
      });
    }
  }

  Future<void> submitAttendance() async {
    if (isSubmitting) return;
    final loadingTimer = MinimumLoadingTimer();
    setState(() {
      isSubmitting = true;
    });

    try {
      final records = attendanceMap.entries.map((entry) {
        return {"student_id": entry.key, "present": entry.value};
      }).toList();

      await AttendanceService.markManualAttendance(
        widget.subjectId,
        records,
        date: date,
      );

      // Reload the saved day before returning so the next view starts from
      // server state rather than a stale local attendance map.
      await fetchStudents();
      await loadingTimer.wait();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Attendance submitted successfully"),
            ],
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      await loadingTimer.wait();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text("Error submitting attendance: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  ImageProvider? _avatarProvider(dynamic avatar) {
    if (avatar == null) {
      return null;
    }

    final value = avatar.toString().trim();

    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith("http://") || value.startsWith("https://")) {
      return NetworkImage(value);
    }

    try {
      final base64Value = value.contains(",") ? value.split(",").last : value;

      return MemoryImage(base64Decode(base64Value));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          "Manual Attendance",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      body: Stack(
        children: [
          if (isLoading)
            const AppLoadingView(message: 'Loading student attendance…')
          else if (loadError != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loadError!),
                  TextButton(
                    onPressed: fetchStudents,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    children: [
                      _subjectHeader(),

                      const SizedBox(height: 18),

                      _bulkActions(),

                      const SizedBox(height: 22),

                      _sectionHeader(),

                      const SizedBox(height: 10),

                      if (students.isEmpty)
                        _emptyState()
                      else
                        ...students.map(_studentCard),
                    ],
                  ),
                ),

                _submitButton(),
              ],
            ),
          if (isSubmitting)
            const Positioned.fill(
              child: AppLoadingView(
                message: 'Saving attendance and refreshing…',
                overlay: true,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SUBJECT HEADER
  // =========================================================

  Widget _subjectHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5B45D9), Color(0xff8068F2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mark Attendance",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BULK ACTIONS
  // =========================================================

  Widget _bulkActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            title: "Mark All Present",
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            background: const Color(0xffE8F8EE),
            onTap: _markAllPresent,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionButton(
            title: "Mark All Absent",
            icon: Icons.cancel_outlined,
            color: Colors.red,
            background: const Color(0xffffeeee),
            onTap: _markAllAbsent,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllPresent() {
    setState(() {
      for (final student in students) {
        attendanceMap[student['id']] = true;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (final student in students) {
        attendanceMap[student['id']] = false;
      }
    });
  }

  // =========================================================
  // STUDENTS
  // =========================================================

  Widget _sectionHeader() {
    return const Text(
      "Students",
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _studentCard(dynamic student) {
    final id = student['id'];

    final isPresent = attendanceMap[id] ?? false;

    final avatarProvider = _avatarProvider(student['avatar']);

    final accent = isPresent ? Colors.green : Colors.red;

    final background = isPresent
        ? const Color(0xffF3FBF5)
        : const Color(0xffFFF5F5);

    return GestureDetector(
      onTap: () {
        setState(() {
          attendanceMap[id] = !isPresent;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPresent
                ? const Color(0xffD9F1DE)
                : const Color(0xffffdddd),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 55,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 12),

            CircleAvatar(
              radius: 25,
              backgroundColor: background,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Icon(Icons.person_rounded, color: accent)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name']?.toString() ?? "Student",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Roll: ${student['roll'] ?? '-'}",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    isPresent ? "Present" : "Absent",
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xffEEEAFE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: Colors.deepPurple,
              size: 30,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            "No students found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Widget _submitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            disabledBackgroundColor: Colors.deepPurple.withValues(alpha: 0.55),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isSubmitting
              ? const Text('Saving…')
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 21),
                    SizedBox(width: 8),
                    Text(
                      "Submit Attendance",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
