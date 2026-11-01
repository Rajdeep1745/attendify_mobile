import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/attendance_service.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final String subjectId;
  final String subjectName;

  const ResultScreen({
    super.key,
    required this.result,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List students = [];

  Map<String, dynamic> studentMap = {};

  late List attendance;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    attendance = List.from(widget.result["attendance"] ?? []);

    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final data = await AttendanceService.fetchStudents(widget.subjectId);

      if (!mounted) return;

      setState(() {
        students = data;

        studentMap = {for (final student in students) student["id"]: student};
      });
    } catch (e) {
      debugPrint("Failed to load students: $e");
    }
  }

  int get presentCount => attendance.where((e) => e["present"] == true).length;

  int get absentCount => attendance.where((e) => e["present"] == false).length;

  Future<void> saveChanges() async {
    try {
      setState(() {
        saving = true;
      });

      await AttendanceService.saveOverrides(
        widget.subjectId,
        widget.result["date"],
        attendance,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attendance saved")));

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f5f7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text("Attendance Result • ${widget.subjectName}"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  statBox("Present", presentCount, Colors.green),
                  statBox("Absent", absentCount, Colors.red),
                  statBox("Total", attendance.length, Colors.deepPurple),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView.builder(
                itemCount: attendance.length,
                itemBuilder: (_, index) {
                  final student = attendance[index];

                  final present = student["present"] == true;

                  final name = student["name"] ?? "Unknown";

                  final roll = student["roll"] ?? "-";

                  final avatar = student["avatar"];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        student["present"] = !present;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: present
                            ? Colors.green.withAlpha(20)
                            : Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: present ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                avatar != null && avatar.toString().isNotEmpty
                                ? MemoryImage(
                                    base64Decode(
                                      avatar.toString().contains(',')
                                          ? avatar.toString().split(',').last
                                          : avatar,
                                    ),
                                  )
                                : null,
                            child: avatar == null || avatar.toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  "Roll: $roll",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: present ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              present ? "Present" : "Absent",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: saving ? null : saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Final Attendance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statBox(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}
