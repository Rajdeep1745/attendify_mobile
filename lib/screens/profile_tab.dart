import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import 'change_password_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final nameController = TextEditingController();

  final deptController = TextEditingController();

  String email = "";
  String avatarUrl = "";

  double threshold = 75;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    deptController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    try {
      final newAvatar = await ProfileService.updateAvatar(image);

      if (!mounted) return;

      setState(() {
        avatarUrl = newAvatar;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Profile photo updated"),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("PROFILE PHOTO UPLOAD ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> loadProfile() async {
    try {
      final data = await ProfileService.getProfile();

      if (!mounted) return;

      setState(() {
        nameController.text = data["name"] ?? "";

        deptController.text = data["department"] ?? "";

        email = data["email"] ?? "";

        avatarUrl = data["avatar"] ?? "";

        final value = data["defaultThreshold"];

        threshold = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? "") ?? 75;

        isLoading = false;
      });
    } catch (e) {
      debugPrint("PROFILE LOAD ERROR: $e");

      if (!mounted) return;

      setState(() {
        nameController.text = "";
        deptController.text = "";
        email = "";
        avatarUrl = "";
        threshold = 75;
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
    });

    try {
      await ProfileService.updateProfile(
        name: nameController.text.trim(),
        department: deptController.text.trim(),
        threshold: threshold.toInt(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Profile updated successfully"),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Failed to update profile"),
            ],
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  String get _displayName {
    final name = nameController.text.trim();

    return name.isEmpty ? "Teacher" : name;
  }

  String get _initial {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      return "T";
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _profileHeader(),

          const SizedBox(height: 22),

          _sectionTitle("Personal Information"),

          const SizedBox(height: 12),

          _inputCard(
            label: "Full Name",
            controller: nameController,
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 12),

          _inputCard(
            label: "Department",
            controller: deptController,
            icon: Icons.account_balance_outlined,
          ),

          const SizedBox(height: 12),

          _emailCard(),

          const SizedBox(height: 22),

          _sectionTitle("Security"),

          const SizedBox(height: 12),

          _changePasswordCard(),

          const SizedBox(height: 22),

          _sectionTitle("Attendance Preferences"),

          const SizedBox(height: 12),

          _thresholdCard(),

          const SizedBox(height: 24),

          _saveButton(),
        ],
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5B45D9), Color(0xff8068F2)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Larger profile image
          GestureDetector(
            onTap: isSaving ? null : _changeProfilePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: ClipOval(child: _buildAvatar(avatarUrl)),
                  ),
                ),

                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.deepPurple,
                      size: 19,
                    ),
                  ),
                ),

                if (isSaving)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Larger name
          Text(
            _displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 7),

          // Larger email
          Text(
            email.isEmpty ? "Teacher account" : email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY
  // =========================================================

  Widget _changePasswordCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              _iconBox(
                Icons.lock_reset_rounded,
                Colors.deepPurple,
                const Color(0xffEEEAFE),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Update your account password",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMAIL
  // =========================================================

  Widget _emailCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _iconBox(Icons.email_outlined, Colors.blue, const Color(0xffE8F3FF)),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email Address",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),

                const SizedBox(height: 3),

                Text(
                  email.isEmpty ? "Not available" : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xffE8F8EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Account",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INPUT
  // =========================================================

  Widget _inputCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: _iconBox(icon, Colors.deepPurple, const Color(0xffEEEAFE)),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // THRESHOLD
  // =========================================================

  Widget _thresholdCard() {
    final value = threshold.round();

    final color = value >= 75
        ? Colors.green
        : value >= 60
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(
                Icons.tune_rounded,
                Colors.deepPurple,
                const Color(0xffEEEAFE),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attendance Threshold",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "Minimum attendance target",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$value%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.deepPurple,
              inactiveTrackColor: const Color(0xffE8E5F5),
              thumbColor: Colors.deepPurple,
              overlayColor: Colors.deepPurple.withValues(alpha: 0.10),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: threshold,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  threshold = value;
                });
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "0%",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),

              Text(
                "Recommended: 75%",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                "100%",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SAVE
  // =========================================================

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          disabledBackgroundColor: Colors.deepPurple.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Save Changes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                ],
              ),
      ),
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

  Widget _iconBox(IconData icon, Color color, Color background) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xffEEEAFE),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatar) {
    if (avatar.startsWith("data:image")) {
      try {
        final base64Str = avatar.split(",").last;

        final bytes = base64Decode(base64Str);

        return Image.memory(bytes, width: 120, height: 120, fit: BoxFit.cover);
      } catch (_) {
        return _fallbackAvatar();
      }
    }

    if (avatar.startsWith("http://") || avatar.startsWith("https://")) {
      return Image.network(
        avatar,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackAvatar();
        },
      );
    }

    return _fallbackAvatar();
  }
}
