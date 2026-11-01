import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final departmentController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  late TapGestureRecognizer loginRecognizer;

  bool isLoading = false;
  bool obscurePassword = true;

  String selectedRole = "student";

  @override
  void initState() {
    super.initState();

    loginRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pop(context);
      };
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    passwordController.dispose();
    loginRecognizer.dispose();
    super.dispose();
  }

  Future<void> signupUser() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await AuthService.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        department: departmentController.text.trim(),
        role: selectedRole,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        showSnack("Account created successfully");

        Navigator.pop(context);
      } else {
        showSnack(result["message"]);
      }
    } catch (e) {
      showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  InputDecoration inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xfffafafa),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xffe0e0e0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xff7b4dff), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Container(
              width: 380,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const Text(
                      "Smart Attendance",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Create your account",
                      style: TextStyle(color: Color(0xff777777)),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: nameController,
                      decoration: inputDecoration(hint: "Full Name"),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter name" : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: emailController,
                      decoration: inputDecoration(hint: "Email"),
                      validator: (v) => v == null || !v.contains("@")
                          ? "Enter valid email"
                          : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: departmentController,
                      decoration: inputDecoration(hint: "Department"),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: inputDecoration(
                        hint: "Password",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? "Minimum 6 characters"
                          : null,
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: inputDecoration(hint: "Role"),
                      items: const [
                        DropdownMenuItem(
                          value: "student",
                          child: Text("Student"),
                        ),
                        DropdownMenuItem(
                          value: "teacher",
                          child: Text("Teacher"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,

                      child: ElevatedButton(
                        onPressed: isLoading ? null : signupUser,

                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xff7b4dff), Color(0xff6a3df0)],
                            ),
                          ),

                          child: Container(
                            alignment: Alignment.center,
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xff666666),
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: "Login",
                            style: const TextStyle(
                              color: Color(0xff7b4dff),
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: loginRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
