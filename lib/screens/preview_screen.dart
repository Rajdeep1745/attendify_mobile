import 'dart:io';

import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import 'result_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final String subjectId;
  final String subjectName;

  const PreviewScreen({
    super.key,
    required this.imagePath,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool loading = false;

  Future<void> uploadImage() async {
    try {
      setState(() {
        loading = true;
      });

      final result = await AttendanceService.uploadAttendance(
        widget.imagePath,
        widget.subjectId,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            subjectId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),

      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Retake"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : uploadImage,
                    child: Text(loading ? "Uploading..." : "Upload"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
