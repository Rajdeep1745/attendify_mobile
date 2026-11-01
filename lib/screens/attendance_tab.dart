import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';

class AttendanceTab extends StatefulWidget {
  final SubjectModel? selectedSubject;

  const AttendanceTab({super.key, required this.selectedSubject});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;

  List<dynamic> students = [];
  List<dynamic> absentees = [];

  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant AttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedSubject?.subjectId !=
        widget.selectedSubject?.subjectId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final subject = widget.selectedSubject;

    if (subject == null) {
      if (!mounted) return;

      setState(() {
        students = [];
        stats = {};
        absentees = [];
        isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final subjectId = subject.subjectId;

      final date = _formatDateForApi(selectedDate);

      // Daily attendance
      final dailyData = await AttendanceService.getDailyAttendance(
        subjectId,
        date,
      );

      // Subject statistics
      final statData = await AttendanceService.getStats(subjectId);

      // Frequent absentees
      List<dynamic> absenteeData = [];

      try {
        absenteeData = await AttendanceService.getFrequentAbsentees(subjectId);
      } catch (_) {
        absenteeData = [];
      }

      if (!mounted) return;

      setState(() {
        students = dailyData;
        stats = statData;
        absentees = absenteeData;
      });
    } catch (e) {
      debugPrint("ATTENDANCE TAB ERROR: $e");

      if (!mounted) return;

      setState(() {
        students = [];
        stats = {};
        absentees = [];
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
    });

    _loadData();
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  String _percentage(dynamic value) {
    final number = _asDouble(value);

    final text = number % 1 == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(1);

    return "$text%";
  }

  dynamic _statValue(String key) {
    return stats[key] ?? 0;
  }

  dynamic _nestedStatValue(String key, String nestedKey) {
    final value = stats[key];

    if (value is Map<String, dynamic>) {
      return value[nestedKey] ?? 0;
    }

    if (value is Map) {
      return value[nestedKey] ?? 0;
    }

    return 0;
  }

  String _initialFor(String name) {
    if (name.trim().isEmpty) {
      return "S";
    }

    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSubject == null) {
      return const Center(
        child: Text("Please select a subject", style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _headerCard(),

          const SizedBox(height: 18),

          _sectionTitle("Attendance Overview"),

          const SizedBox(height: 12),

          _overviewGrid(),

          const SizedBox(height: 22),

          _sectionTitle("Frequent Absentees"),

          const SizedBox(height: 12),

          _absenteesCard(),

          const SizedBox(height: 22),

          _sectionTitle("Daily Attendance"),

          const SizedBox(height: 12),

          _dateCard(),

          const SizedBox(height: 14),

          if (isLoading)
            _loadingCard()
          else if (students.isEmpty)
            _emptyCard(
              "No attendance found for this date.",
              icon: Icons.event_busy_rounded,
            )
          else
            ...students.map(_studentTile),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _headerCard() {
    final subject = widget.selectedSubject!;

    return Container(
      padding: const EdgeInsets.all(22),
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  "Attendance Insights",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "LIVE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            subject.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 16,
                color: Colors.white70,
              ),

              const SizedBox(width: 6),

              Text(
                subject.programme,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("•", style: TextStyle(color: Colors.white54)),
              ),

              Text(
                "Semester ${subject.semester}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KPI GRID
  // =========================================================

  Widget _overviewGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      // Explicit height prevents the KPI
      // content from overflowing.
      mainAxisExtent: 128,

      children: [
        _statCard(
          title: "Classes Held",
          value: "${_statValue('totalClasses')}",
          icon: Icons.class_rounded,
          iconColor: Colors.deepPurple,
          iconBackground: const Color(0xffEEEAFE),
        ),

        _statCard(
          title: "Average Attendance",
          value: _percentage(_statValue('avgAttendance')),
          icon: Icons.donut_large_rounded,
          iconColor: Colors.blue,
          iconBackground: const Color(0xffE8F3FF),
        ),

        _statCard(
          title: "Best Session",
          value: _percentage(_nestedStatValue('bestAttendance', 'percentage')),
          icon: Icons.trending_up_rounded,
          iconColor: Colors.green,
          iconBackground: const Color(0xffE8F8EE),
        ),

        _statCard(
          title: "Lowest Session",
          value: _percentage(_nestedStatValue('worstAttendance', 'percentage')),
          icon: Icons.trending_down_rounded,
          iconColor: Colors.orange,
          iconBackground: const Color(0xfffff2df),
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),

              const Spacer(),

              Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  Widget _dateCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(15),
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
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xffEEEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.deepPurple,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected Date",
                    style: TextStyle(color: Colors.grey, fontSize: 11.5),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 19,
        letterSpacing: -0.2,
      ),
    );
  }

  // =========================================================
  // FREQUENT ABSENTEES
  // =========================================================

  Widget _absenteesCard() {
    if (isLoading && absentees.isEmpty) {
      return _loadingCard();
    }

    if (absentees.isEmpty) {
      return _emptyCard(
        "No frequent absentees yet.",
        icon: Icons.sentiment_satisfied_alt_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [...absentees.take(5).map(_absenteeTile)]),
    );
  }

  Widget _absenteeTile(dynamic student) {
    final name = student is Map ? student["name"]?.toString() ?? "" : "";

    final absences = student is Map ? student["absences"] ?? 0 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffffeeee),
            child: Text(
              _initialFor(name),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? "Student" : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "Frequent absence",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xffffeeee),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$absences absences",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT TILE
  // =========================================================

  Widget _studentTile(dynamic student) {
    final present = student['present'];

    final Color accentColor = present == null
        ? Colors.grey
        : present == true
        ? Colors.green
        : Colors.red;

    final String statusText = present == null
        ? "No Data"
        : present == true
        ? "Present"
        : "Absent";

    final String studentName = student['name']?.toString() ?? 'Student';

    final percentage = student['percentage'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 5),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 58,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 12),

            CircleAvatar(
              radius: 23,
              backgroundColor: accentColor.withValues(alpha: 0.10),
              child: Text(
                _initialFor(studentName),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        "$percentage% attendance",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    statusText,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
  // EMPTY / LOADING
  // =========================================================

  Widget _loadingCard() {
    return Container(
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const CircularProgressIndicator(color: Colors.deepPurple),
    );
  }

  Widget _emptyCard(String message, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline_rounded, color: Colors.grey.shade500),

          const SizedBox(width: 12),

          Expanded(
            child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
