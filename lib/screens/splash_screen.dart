import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import 'main_shell.dart';
import 'student_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // ---------------------------------------------------------
    // Check whether the saved token is actually valid.
    //
    // This also gets the REAL role from the backend.
    // ---------------------------------------------------------

    final user = await AuthService.validateSession();

    // Small splash delay.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // ---------------------------------------------------------
    // NO VALID SESSION
    // ---------------------------------------------------------

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      return;
    }

    // ---------------------------------------------------------
    // VALID SESSION
    // ---------------------------------------------------------

    final role = user["role"]?.toString().toLowerCase();

    // ---------------------------------------------------------
    // STUDENT
    // ---------------------------------------------------------

    if (role == "student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentShell()),
      );

      return;
    }

    // ---------------------------------------------------------
    // TEACHER
    // ---------------------------------------------------------

    if (role == "teacher") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );

      return;
    }

    // ---------------------------------------------------------
    // Unknown role
    // ---------------------------------------------------------

    await AuthService.clearSession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.school, size: 72, color: Color(0xff7b4dff)),

            SizedBox(height: 18),

            Text(
              "Smart Attendance",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 24),

            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
