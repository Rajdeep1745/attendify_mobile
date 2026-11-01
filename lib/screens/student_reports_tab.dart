import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';

class StudentReportsTab extends StatefulWidget {
  final List<SubjectModel> subjects;

  const StudentReportsTab({super.key, required this.subjects});

  @override
  State<StudentReportsTab> createState() => _StudentReportsTabState();
}

class _StudentReportsTabState extends State<StudentReportsTab> {
  SubjectModel? selectedSubject;

  Map<String, dynamic> report = {};

  bool isLoading = false;
  bool isOverviewLoading = false;

  List<Map<String, dynamic>> overviewData = [];

  @override
  void initState() {
    super.initState();

    // Do NOT automatically select a subject.
    //
    // The initial screen is the overall reports dashboard.
    selectedSubject = null;

    _loadOverview();
  }

  @override
  void didUpdateWidget(covariant StudentReportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.subjects != widget.subjects) {
      selectedSubject = null;
      report = {};

      _loadOverview();
    }
  }

  // =========================================================
  // LOAD OVERVIEW
  // =========================================================

  Future<void> _loadOverview() async {
    if (widget.subjects.isEmpty) {
      if (!mounted) return;

      setState(() {
        overviewData = [];
        isOverviewLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isOverviewLoading = true;
      });
    }

    final results = <Map<String, dynamic>>[];

    for (final subject in widget.subjects) {
      try {
        final data = await AttendanceService.getStudentSubjectOverview(
          subject.subjectId,
        );

        final attendance = _double(data["myAttendance"]);

        results.add({
          "subject": subject,
          "attendance": attendance,
          "threshold": subject.threshold,
        });
      } catch (_) {
        // One failed subject should not prevent the
        // other subjects from appearing.
      }
    }

    if (!mounted) return;

    setState(() {
      overviewData = results;
      isOverviewLoading = false;
    });
  }

  // =========================================================
  // LOAD SELECTED SUBJECT REPORT
  // =========================================================

  Future<void> _loadReport() async {
    final subject = selectedSubject;

    if (subject == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = true;
      report = {};
    });

    try {
      final data = await AttendanceService.getStudentSubjectReport(
        subject.subjectId,
      );

      if (!mounted) return;

      setState(() {
        report = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        report = {};
        isLoading = false;
      });
    }
  }

  // =========================================================
  // SAFE NUMBER CONVERSION
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
  // CLASSES NEEDED TO REACH THRESHOLD
  // =========================================================

  int _classesNeeded(
    double attendance,
    int totalClasses,
    int attendedClasses,
    int threshold,
  ) {
    if (attendance >= threshold || totalClasses <= 0) {
      return 0;
    }

    final target = threshold / 100.0;

    if (target >= 1) {
      return 0;
    }

    final numerator = (target * totalClasses) - attendedClasses;

    final denominator = 1 - target;

    return math.max(0, (numerator / denominator).ceil());
  }

  // =========================================================
  // CLASSES THAT CAN BE MISSED
  // =========================================================

  int _classesCanMiss(
    double attendance,
    int totalClasses,
    int attendedClasses,
    int threshold,
  ) {
    if (attendance < threshold || totalClasses <= 0) {
      return 0;
    }

    final target = threshold / 100.0;

    if (target <= 0) {
      return 999;
    }

    final result = (attendedClasses / target) - totalClasses;

    return math.max(0, result.floor());
  }

  // =========================================================
  // SUBJECT SELECTION
  // =========================================================

  void _selectSubject(SubjectModel? subject) {
    if (subject == null) {
      setState(() {
        selectedSubject = null;
        report = {};
      });

      return;
    }

    setState(() {
      selectedSubject = subject;
      report = {};
    });

    _loadReport();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      color: Colors.deepPurple,

      onRefresh: () async {
        if (selectedSubject == null) {
          await _loadOverview();
        } else {
          await _loadReport();
        }
      },

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),

        children: [
          _subjectSelector(),

          const SizedBox(height: 18),

          if (selectedSubject == null)
            _buildOverview()
          else if (isLoading)
            _loading()
          else if (report.isEmpty)
            _reportError()
          else
            _buildSubjectReport(),
        ],
      ),
    );
  }

  // =========================================================
  // SUBJECT SELECTOR
  // =========================================================

  Widget _subjectSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade100),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<SubjectModel>(
          value: selectedSubject,

          isExpanded: true,

          hint: const Text(
            "Select a subject",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),

          icon: const Icon(Icons.keyboard_arrow_down_rounded),

          borderRadius: BorderRadius.circular(18),

          items: [
            const DropdownMenuItem<SubjectModel>(
              value: null,

              child: Text(
                "All subjects",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),

            ...widget.subjects.map((subject) {
              return DropdownMenuItem<SubjectModel>(
                value: subject,

                child: Text(
                  subject.name,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],

          onChanged: _selectSubject,
        ),
      ),
    );
  }

  // =========================================================
  // OVERVIEW
  // =========================================================

  Widget _buildOverview() {
    if (isOverviewLoading) {
      return _loading();
    }

    if (overviewData.isEmpty) {
      return _overviewEmpty();
    }

    int above = 0;
    int below = 0;

    double totalAttendance = 0;

    for (final item in overviewData) {
      final attendance = item["attendance"] as double;

      final threshold = item["threshold"] as int;

      totalAttendance += attendance;

      if (attendance >= threshold) {
        above++;
      } else {
        below++;
      }
    }

    final average = totalAttendance / overviewData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Your attendance insights",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "A quick overview of your performance across all subjects.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),

        const SizedBox(height: 16),

        _overviewStats(average, above, below),

        const SizedBox(height: 20),

        _overviewChart(),

        const SizedBox(height: 20),

        _performanceList(),

        const SizedBox(height: 20),

        _selectSubjectPrompt(),
      ],
    );
  }

  // =========================================================
  // OVERVIEW STATS
  // =========================================================

  Widget _overviewStats(double average, int above, int below) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Row(
        children: [
          Expanded(
            child: _overviewMetric(
              "${average.toStringAsFixed(1)}%",
              "Average",
              Icons.analytics_rounded,
              Colors.deepPurple,
            ),
          ),

          Expanded(
            child: _overviewMetric(
              above.toString(),
              "On track",
              Icons.check_circle_rounded,
              Colors.green,
            ),
          ),

          Expanded(
            child: _overviewMetric(
              below.toString(),
              "Needs attention",
              Icons.warning_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),

        const SizedBox(height: 7),

        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );
  }

  // =========================================================
  // OVERVIEW BAR CHART
  // =========================================================

  Widget _overviewChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Subject comparison",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            "Your attendance in every enrolled subject.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 230,

            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 100,

                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                ),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}%",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= overviewData.length) {
                          return const SizedBox();
                        }

                        final subject =
                            overviewData[index]["subject"] as SubjectModel;

                        String name = subject.name;

                        if (name.length > 8) {
                          name = "${name.substring(0, 8)}…";
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 8.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: List.generate(overviewData.length, (index) {
                  final attendance =
                      overviewData[index]["attendance"] as double;

                  final threshold = overviewData[index]["threshold"] as int;

                  final barColor = attendance >= threshold
                      ? Colors.green
                      : Colors.orange;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: attendance,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        color: barColor,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              _legend(Colors.green, "Above threshold"),

              const SizedBox(width: 16),

              _legend(Colors.orange, "Needs attention"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 5),

        Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 9.5),
        ),
      ],
    );
  }

  // =========================================================
  // PERFORMANCE LIST
  // =========================================================

  Widget _performanceList() {
    final sorted = List<Map<String, dynamic>>.from(overviewData);

    sorted.sort(
      (a, b) =>
          (b["attendance"] as double).compareTo(a["attendance"] as double),
    );

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Performance by subject",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          ...sorted.map((item) {
            final subject = item["subject"] as SubjectModel;

            final attendance = item["attendance"] as double;

            final threshold = item["threshold"] as int;

            final color = attendance >= threshold
                ? Colors.green
                : Colors.orange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),

              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      Text(
                        "${attendance.toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),

                    child: LinearProgressIndicator(
                      value: (attendance / 100).clamp(0.0, 1.0),

                      minHeight: 6,

                      backgroundColor: Colors.grey.shade100,

                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================
  // SELECT SUBJECT PROMPT
  // =========================================================

  Widget _selectSubjectPrompt() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xffEEEAFE),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.10),

              borderRadius: BorderRadius.circular(13),
            ),

            child: const Icon(Icons.insights_rounded, color: Colors.deepPurple),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore a subject",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),

                SizedBox(height: 4),

                Text(
                  "Select a subject above for detailed trends, threshold projections and attendance breakdown.",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    height: 1.35,
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
  // SUBJECT REPORT
  // =========================================================

  Widget _buildSubjectReport() {
    final subject = selectedSubject!;

    final percentage = _double(report["myAttendance"]);

    final average = _double(report["subjectAverage"]);

    final total = _int(report["totalClasses"]);

    final attended = _int(report["attendedClasses"]);

    final threshold = _int(report["threshold"]);

    final absent = math.max(0, total - attended);

    final needed = _classesNeeded(percentage, total, attended, threshold);

    final canMiss = _classesCanMiss(percentage, total, attended, threshold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _overviewCard(subject, percentage, threshold, needed, canMiss),

        const SizedBox(height: 16),

        _quickStats(total, attended, absent, average),

        const SizedBox(height: 20),

        const Text(
          "Attendance trend",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          "Your cumulative attendance after each class.",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
        ),

        const SizedBox(height: 10),

        _trendChart(threshold),

        const SizedBox(height: 20),

        const Text(
          "Attendance breakdown",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          "How your attended classes are distributed.",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
        ),

        const SizedBox(height: 10),

        _breakdownCard(attended, absent, total),

        const SizedBox(height: 20),

        const Text(
          "Compared with the subject",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          "Your attendance versus the subject average.",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
        ),

        const SizedBox(height: 10),

        _comparisonCard(percentage, average),

        const SizedBox(height: 20),

        _insightCard(percentage, threshold, needed, canMiss, total),
      ],
    );
  }

  // =========================================================
  // SUBJECT OVERVIEW CARD
  // =========================================================

  Widget _overviewCard(
    SubjectModel subject,
    double percentage,
    int threshold,
    int needed,
    int canMiss,
  ) {
    final above = percentage >= threshold;

    return Container(
      padding: const EdgeInsets.all(20),

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
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  "Threshold $threshold%",

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                "${percentage.toStringAsFixed(1)}%",

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

                child: Text(
                  above ? "On track" : "Needs attention",

                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),

              minHeight: 8,

              backgroundColor: Colors.white.withValues(alpha: 0.16),

              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),

              borderRadius: BorderRadius.circular(16),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    above
                        ? canMiss == 0
                              ? "You are currently at the threshold. Attend the next classes to create a safety margin."
                              : "You can miss $canMiss more ${canMiss == 1 ? "class" : "classes"} and remain at the threshold."
                        : needed == 0
                        ? "You are at the threshold."
                        : "Attend the next $needed ${needed == 1 ? "class" : "classes"} to reach the threshold.",

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
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
  // QUICK STATS
  // =========================================================

  Widget _quickStats(int total, int attended, int absent, double average) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Row(
        children: [
          Expanded(
            child: _metric(
              Icons.calendar_month_rounded,
              total.toString(),
              "Classes",
              Colors.deepPurple,
            ),
          ),

          Expanded(
            child: _metric(
              Icons.check_circle_rounded,
              attended.toString(),
              "Present",
              Colors.green,
            ),
          ),

          Expanded(
            child: _metric(
              Icons.cancel_rounded,
              absent.toString(),
              "Absent",
              Colors.red,
            ),
          ),

          Expanded(
            child: _metric(
              Icons.groups_rounded,
              "${average.toStringAsFixed(0)}%",
              "Subject avg",
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 21),

        const SizedBox(height: 7),

        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 9.5),
        ),
      ],
    );
  }

  // =========================================================
  // TREND CHART
  // =========================================================

  Widget _trendChart(int threshold) {
    final recent = report["recentAttendance"];

    if (recent is! List || recent.isEmpty) {
      return _emptyChart("Not enough attendance history to show a trend.");
    }

    final ordered = recent.reversed.toList();

    int attended = 0;

    final spots = <FlSpot>[];

    for (int i = 0; i < ordered.length; i++) {
      final item = ordered[i];

      if (item["status"]?.toString() == "Present") {
        attended++;
      }

      final percentage = (attended / (i + 1)) * 100;

      spots.add(FlSpot(i.toDouble(), percentage));
    }

    if (spots.isEmpty) {
      return _emptyChart("Not enough attendance history to show a trend.");
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Column(
        children: [
          SizedBox(
            height: 235,

            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,

                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                ),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}%",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: spots.length > 1,
                      reservedSize: 28,
                      interval: math
                          .max(1, (spots.length / 4).floor())
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= ordered.length) {
                          return const SizedBox();
                        }

                        final date = ordered[index]["date"]?.toString();

                        final parsed = DateTime.tryParse(date ?? "");

                        if (parsed == null) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            "${parsed.day}/${parsed.month}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: threshold.toDouble(),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length <= 12),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurple.withValues(alpha: 0.08),
                    ),
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              _legend(Colors.deepPurple, "Your attendance"),

              const SizedBox(width: 16),

              _legend(Colors.orange, "Threshold"),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BREAKDOWN
  // =========================================================

  Widget _breakdownCard(int attended, int absent, int total) {
    if (total == 0) {
      return _emptyChart("No classes have been conducted yet.");
    }

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Row(
        children: [
          SizedBox(
            width: 125,
            height: 125,

            child: PieChart(
              PieChartData(
                centerSpaceRadius: 34,

                sectionsSpace: 2,

                sections: [
                  PieChartSectionData(
                    value: attended.toDouble(),
                    title: attended.toString(),
                    radius: 42,
                    color: Colors.green,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (absent > 0)
                    PieChartSectionData(
                      value: absent.toDouble(),
                      title: absent.toString(),
                      radius: 42,
                      color: Colors.red.shade400,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _legendRow(Colors.green, "Present", attended),

                const SizedBox(height: 13),

                _legendRow(Colors.red.shade400, "Absent", absent),

                const SizedBox(height: 16),

                Text(
                  "$total classes conducted",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // =========================================================
  // COMPARISON
  // =========================================================

  Widget _comparisonCard(double mine, double average) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Column(
        children: [
          _comparisonBar("Your attendance", mine, Colors.deepPurple),

          const SizedBox(height: 17),

          _comparisonBar("Subject average", average, Colors.orange),
        ],
      ),
    );
  }

  Widget _comparisonBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            Text(
              "${value.toStringAsFixed(1)}%",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),

          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),

            minHeight: 8,

            backgroundColor: Colors.grey.shade100,

            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INSIGHT
  // =========================================================

  Widget _insightCard(
    double percentage,
    int threshold,
    int needed,
    int canMiss,
    int total,
  ) {
    final above = percentage >= threshold;

    late String title;
    late String message;
    late IconData icon;
    late Color color;

    if (total == 0) {
      title = "No attendance data yet";
      message =
          "Once classes are conducted, your attendance projection will appear here.";
      icon = Icons.info_outline_rounded;
      color = Colors.deepPurple;
    } else if (above) {
      title = "You are on track";
      message = canMiss == 0
          ? "You are currently at the threshold. Try to attend the next classes to create a safety margin."
          : "You can miss $canMiss more ${canMiss == 1 ? "class" : "classes"} before falling below the $threshold% threshold.";
      icon = Icons.verified_rounded;
      color = Colors.green;
    } else {
      title = "Attendance needs attention";
      message =
          "You need to attend the next $needed ${needed == 1 ? "class" : "classes"} consecutively to reach the $threshold% threshold.";
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11.5,
                    height: 1.4,
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
  // LOADING
  // =========================================================

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 90),

      child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
    );
  }

  // =========================================================
  // REPORT ERROR
  // =========================================================

  Widget _reportError() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.orange, size: 38),

          SizedBox(height: 10),

          Text(
            "Unable to load this report",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 5),

          Text(
            "Pull down to try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY CHART
  // =========================================================

  Widget _emptyChart(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Text(
        message,

        textAlign: TextAlign.center,

        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    );
  }

  // =========================================================
  // EMPTY OVERVIEW
  // =========================================================

  Widget _overviewEmpty() {
    return Container(
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.deepPurple, size: 42),

          SizedBox(height: 12),

          Text(
            "No attendance data yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 5),

          Text(
            "Reports will appear once attendance has been recorded.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY SUBJECT STATE
  // =========================================================

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(20),

      children: [
        const SizedBox(height: 100),

        Icon(
          Icons.analytics_outlined,
          size: 48,
          color: Colors.deepPurple.shade300,
        ),

        const SizedBox(height: 14),

        const Text(
          "No subjects available",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Text(
          "Reports will appear once you are enrolled in a subject.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
