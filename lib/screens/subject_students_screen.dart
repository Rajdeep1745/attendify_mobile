import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/attendance_service.dart';
import '../widgets/app_loading_view.dart';

class SubjectStudentsScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectStudentsScreen({super.key, required this.subject});

  @override
  State<SubjectStudentsScreen> createState() => _SubjectStudentsScreenState();
}

class _SubjectStudentsScreenState extends State<SubjectStudentsScreen> {
  List<Map<String, dynamic>> students = [];
  String? error;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    final loadingTimer = MinimumLoadingTimer();
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final rows = await AttendanceService.fetchStudents(
        widget.subject.subjectId,
      );
      await loadingTimer.wait();
      if (!mounted) return;
      setState(() {
        students = rows.map((row) => Map<String, dynamic>.from(row)).toList();
        isLoading = false;
      });
    } catch (exception) {
      await loadingTimer.wait();
      if (!mounted) return;
      setState(() {
        error = exception.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  ImageProvider? _avatarFor(Map<String, dynamic> student) {
    final avatar = student['avatar']?.toString() ?? '';
    if (avatar.isEmpty) return null;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }

    try {
      return MemoryImage(base64Decode(avatar.split(',').last));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: _loadStudents,
        child: isLoading
            ? const AppLoadingView(message: 'Loading enrolled students…')
            : error != null
            ? _messageView(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load students',
                message: error!,
                showRetry: true,
              )
            : students.isEmpty
            ? _messageView(
                icon: Icons.groups_outlined,
                title: 'No enrolled students',
                message: 'Students assigned to this subject will appear here.',
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: students.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${students.length} enrolled student${students.length == 1 ? '' : 's'} • ${widget.subject.programme} · Semester ${widget.subject.semester}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  }

                  final student = students[index - 1];
                  final name = student['name']?.toString() ?? 'Student';
                  final roll = student['roll']?.toString() ?? '';
                  final attendance = student['attendance'];
                  final percentage = attendance is num
                      ? attendance.toStringAsFixed(1)
                      : double.tryParse(
                          attendance?.toString() ?? '',
                        )?.toStringAsFixed(1);
                  final avatar = _avatarFor(student);

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xffEEEAFE),
                            backgroundImage: avatar,
                            child: avatar == null
                                ? Text(
                                    name.isEmpty ? '?' : name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (roll.isNotEmpty)
                                  Text(
                                    'Roll $roll',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (percentage != null)
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _messageView({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 48, color: Colors.deepPurple),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        if (showRetry) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _loadStudents,
              child: const Text('Try again'),
            ),
          ),
        ],
      ],
    );
  }
}
