import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ProfileService.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, bool obscure, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: toggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
      filled: true,
      fillColor: const Color(0xffF7F7FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffE8E5F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff5B45D9), Color(0xff8068F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure your account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Choose a strong password you have not used before.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentController,
                    obscureText: _obscureCurrent,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration(
                      'Current password',
                      _obscureCurrent,
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newController,
                    obscureText: _obscureNew,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration(
                      'New password',
                      _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter a new password';
                      if (value.length < 8) return 'Use at least 8 characters';
                      if (value == _currentController.text)
                        return 'Choose a password different from the current one';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration(
                      'Confirm new password',
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) => value != _newController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.deepPurple.withValues(
                          alpha: 0.55,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                              ),
                            ),
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
}
