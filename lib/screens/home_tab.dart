import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';
import 'camera_screen.dart';
import 'manual_attendance_screen.dart';

class HomeTab extends StatefulWidget {
  final SubjectModel? selectedSubject;

  const HomeTab({super.key, required this.selectedSubject});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  double attendancePercentage = 0;
  int totalClasses = 0;

  int currentThreshold = 75;
  bool isUpdatingThreshold = false;

  double todayAttendancePercentage = 0;
  int todayPresentCount = 0;

  bool todayAttendanceTaken = false;
  bool isStatsLoading = false;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedSubject?.subjectId !=
        widget.selectedSubject?.subjectId) {
      loadStats();
    }
  }

  Future<void> loadStats() async {
    final subject = widget.selectedSubject;

    if (subject == null) {
      if (!mounted) return;

      setState(() {
        attendancePercentage = 0;
        totalClasses = 0;
        currentThreshold = 75;
        todayAttendancePercentage = 0;
        todayPresentCount = 0;
        todayAttendanceTaken = false;
        isStatsLoading = false;
      });

      return;
    }

    setState(() {
      isStatsLoading = true;
    });

    if (mounted) {
      setState(() {
        currentThreshold = subject.threshold;
      });
    }

    final today = DateTime.now().toIso8601String().split("T").first;

    try {
      final statsFuture = AttendanceService.getStats(subject.subjectId);

      final dailyFuture = AttendanceService.getDailyAttendance(
        subject.subjectId,
        today,
      );

      final results = await Future.wait([statsFuture, dailyFuture]);

      final stats = results[0] as Map<String, dynamic>;

      final daily = results[1] as List<dynamic>;

      int presentCount = 0;

      for (final student in daily) {
        final present = student["present"];

        if (present == true) {
          presentCount++;
        }
      }

      final totalStudents = daily.length;

      final hasAnyAttendance = daily.any(
        (student) => student["present"] != null,
      );

      final todayPercentage = totalStudents == 0
          ? 0.0
          : (presentCount / totalStudents) * 100;

      if (!mounted) return;

      setState(() {
        attendancePercentage =
            double.tryParse(stats["avgAttendance"]?.toString() ?? "0") ?? 0;

        totalClasses =
            int.tryParse(stats["totalClasses"]?.toString() ?? "0") ?? 0;

        todayPresentCount = presentCount;

        todayAttendancePercentage = todayPercentage;

        todayAttendanceTaken = hasAnyAttendance;

        isStatsLoading = false;
      });
    } catch (e) {
      debugPrint("HOME STATS ERROR: $e");

      if (!mounted) return;

      setState(() {
        attendancePercentage = 0;
        totalClasses = 0;
        todayAttendancePercentage = 0;
        todayPresentCount = 0;
        todayAttendanceTaken = false;
        isStatsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.selectedSubject;

    final totalStudents = subject?.totalStudents ?? 0;

    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: loadStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _welcomeHeader(),

          const SizedBox(height: 18),

          _subjectCard(subject),

          const SizedBox(height: 22),

          _sectionTitle("Subject Overview"),

          const SizedBox(height: 12),

          _overviewGrid(totalStudents: totalStudents),

          const SizedBox(height: 24),

          _sectionTitle("Quick Actions"),

          const SizedBox(height: 12),

          _actionCard(
            title: "Automatic Attendance",
            subtitle: "Use face recognition to mark attendance",
            icon: Icons.camera_alt_rounded,
            iconColor: Colors.deepPurple,
            iconBackground: const Color(0xffEEEAFE),
            onTap: () => _openCamera(subject),
          ),

          const SizedBox(height: 12),

          _actionCard(
            title: "Manual Attendance",
            subtitle: "Mark students present or absent",
            icon: Icons.edit_calendar_rounded,
            iconColor: Colors.orange,
            iconBackground: const Color(0xfffff2df),
            onTap: () => _openManualAttendance(subject),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WELCOME
  // =========================================================

  Widget _welcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Good day 👋",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "Here's how your subject attendance is looking.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  // =========================================================
  // SUBJECT CARD
  // =========================================================

  Widget _subjectCard(SubjectModel? subject) {
    if (subject == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(
              "Select a subject to continue",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
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
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Subject",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${subject.programme} • Semester ${subject.semester}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KPI GRID
  // =========================================================

  Widget _overviewGrid({required int totalStudents}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: 128,
      children: [
        _statCard(
          value: "$totalStudents",
          title: "Total Students",
          icon: Icons.groups_rounded,
          iconColor: Colors.deepPurple,
          iconBackground: const Color(0xffEEEAFE),
        ),

        // TOP RIGHT
        _statCard(
          value: isStatsLoading
              ? "..."
              : todayAttendanceTaken
              ? "${todayAttendancePercentage.toStringAsFixed(0)}%"
              : "Not Taken",
          title: "Today's Attendance",
          icon: Icons.today_rounded,
          iconColor: Colors.blue,
          iconBackground: const Color(0xffE8F3FF),
        ),

        // BOTTOM LEFT
        _statCard(
          value: "$currentThreshold%",
          title: "Attendance Threshold",
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          iconBackground: const Color(0xfffff2df),
          onTap: () => _showThresholdDialog(),
        ),

        // BOTTOM RIGHT
        _statCard(
          value: isStatsLoading ? "..." : "$totalClasses",
          title: "Classes Held",
          icon: Icons.class_rounded,
          iconColor: Colors.green,
          iconBackground: const Color(0xffE8F8EE),
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
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
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
                      fontSize: 18,
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
        ),
      ),
    );
  }

  // =========================================================
  // QUICK ACTIONS
  // =========================================================

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThresholdDialog() async {
    final subject = widget.selectedSubject;

    if (subject == null) {
      _showSelectSubject();
      return;
    }

    int selectedThreshold = currentThreshold;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Attendance Threshold",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set the minimum attendance required for ${subject.name}.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "$selectedThreshold%",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: selectedThreshold.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: "$selectedThreshold%",
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedThreshold = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isUpdatingThreshold
                      ? null
                      : () async {
                          setDialogState(() {
                            isUpdatingThreshold = true;
                          });

                          try {
                            final updatedThreshold =
                                await AttendanceService.updateThreshold(
                                  subject.subjectId,
                                  selectedThreshold,
                                );

                            if (!mounted) return;

                            setState(() {
                              currentThreshold = updatedThreshold;
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Threshold updated to $updatedThreshold%",
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isUpdatingThreshold = false;
                            });

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst("Exception: ", ""),
                                ),
                              ),
                            );
                          }
                        },
                  child: isUpdatingThreshold
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _openCamera(SubjectModel? subject) {
    if (subject == null) {
      _showSelectSubject();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          subjectId: subject.subjectId,
          subjectName: subject.name,
        ),
      ),
    );
  }

  void _openManualAttendance(SubjectModel? subject) {
    if (subject == null) {
      _showSelectSubject();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualAttendanceScreen(
          subjectId: subject.subjectId,
          subjectName: subject.name,
        ),
      ),
    );
  }

  void _showSelectSubject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a subject first")),
    );
  }
}
