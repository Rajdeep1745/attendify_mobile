import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/subject_service.dart';
import 'attendance_tab.dart';
import 'subjects_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import '../services/auth_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int currentIndex = 0;

  List<SubjectModel> subjects = [];
  SubjectModel? selectedSubject;

  bool isLoading = true;

  final List<String> titles = ["Home", "Attendance", "Subjects", "Profile"];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadSubjects();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSessionOnResume();
    }
  }

  Future<void> _validateSessionOnResume() async {
    try {
      final user = await AuthService.validateSession();

      if (!mounted) return;

      if (user == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

        return;
      }

      // The backend may have refreshed the role.
      // Reload subjects using the now-validated role.
      await loadSubjects();
    } catch (e) {
      debugPrint("RESUME SESSION CHECK ERROR: $e");

      if (!mounted) return;

      await AuthService.clearSession();

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> loadSubjects() async {
    try {
      final data = await SubjectService.getSubjects();

      if (!mounted) return;

      setState(() {
        subjects = data;

        final selectedId = selectedSubject?.subjectId;

        SubjectModel? nextSelected;

        if (selectedId != null) {
          for (final subject in data) {
            if (subject.subjectId == selectedId) {
              nextSelected = subject;
              break;
            }
          }
        }

        selectedSubject =
            nextSelected ?? (data.length == 1 ? data.first : null);

        isLoading = false;
      });
    } catch (err) {
      debugPrint("LOAD SUBJECTS ERROR: $err");

      if (!mounted) return;

      setState(() {
        subjects = [];
        selectedSubject = null;
        isLoading = false;
      });
    }
  }

  void onSubjectChanged(SubjectModel? subject) {
    setState(() {
      selectedSubject = subject;
    });
  }

  void onSubjectIdChanged(String? subjectId) {
    if (subjectId == null) {
      onSubjectChanged(null);
      return;
    }

    for (final subject in subjects) {
      if (subject.subjectId == subjectId) {
        onSubjectChanged(subject);
        return;
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService.clearSession();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ---------------------------------------------------------
  // GROUP SUBJECTS
  // ---------------------------------------------------------

  Map<String, Map<int, List<SubjectModel>>> _groupSubjects() {
    final grouped = <String, Map<int, List<SubjectModel>>>{};

    for (final subject in subjects) {
      final programme = subject.programme;

      final semester = subject.semester;

      grouped.putIfAbsent(programme, () => <int, List<SubjectModel>>{});

      grouped[programme]!
          .putIfAbsent(semester, () => <SubjectModel>[])
          .add(subject);
    }

    // Keep semesters ordered.
    for (final semesters in grouped.values) {
      for (final subjectList in semesters.values) {
        subjectList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }
    }

    return grouped;
  }

  // ---------------------------------------------------------
  // NESTED SUBJECT SELECTOR
  // ---------------------------------------------------------

  Widget _buildSubjectSelector() {
    if (subjects.isEmpty) {
      return const SizedBox();
    }

    final grouped = _groupSubjects();

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),

      builder: (context, controller, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 210),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xffF6F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selectedSubject?.name ?? "Select Subject",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ],
            ),
          ),
        );
      },

      menuChildren: [
        for (final programmeEntry in grouped.entries)
          SubmenuButton(
            leadingIcon: const Icon(Icons.school_outlined),
            menuChildren: [
              for (final semesterEntry in programmeEntry.value.entries)
                SubmenuButton(
                  leadingIcon: const Icon(Icons.calendar_month_outlined),
                  menuChildren: [
                    for (final subject in semesterEntry.value)
                      MenuItemButton(
                        leadingIcon: Icon(
                          subject.subjectId == selectedSubject?.subjectId
                              ? Icons.check_circle
                              : Icons.menu_book_outlined,
                          color: subject.subjectId == selectedSubject?.subjectId
                              ? Colors.deepPurple
                              : null,
                        ),
                        onPressed: () {
                          onSubjectChanged(subject);
                        },
                        child: Text(subject.name),
                      ),
                  ],
                  child: Text("Semester ${semesterEntry.key}"),
                ),
            ],
            child: Text(programmeEntry.key),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (!isLoading && currentIndex != 3)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildSubjectSelector(),
            ),

          if (currentIndex == 3)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.black87),
                onPressed: () => _confirmLogout(context),
              ),
            ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: currentIndex,
              children: [
                HomeTab(selectedSubject: selectedSubject),

                AttendanceTab(selectedSubject: selectedSubject),

                SubjectsTab(
                  subjects: subjects,
                  selectedSubject: selectedSubject,
                  onSelect: onSubjectChanged,
                  onReload: loadSubjects,
                ),

                const ProfileTab(),
              ],
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,

        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: "Subjects",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
