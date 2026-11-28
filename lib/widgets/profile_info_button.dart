import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileInfoButton extends StatelessWidget {
  const ProfileInfoButton({super.key});

  static const developers = [
    (name: 'Jinea Saha', email: 'jinea05saha@gmail.com', phone: '9433474334'),
    (
      name: 'Rajdeep Sarkar',
      email: 'rajdeepsarkar9117@gmail.com',
      phone: '9126219117',
    ),
  ];

  Future<void> _composeEmail(BuildContext context, String subject) async {
    final recipients = developers.map((developer) => developer.email).join(',');
    final uri = Uri.parse(
      'mailto:$recipients?subject=${Uri.encodeComponent(subject)}',
    );

    try {
      if (await launchUrl(uri)) return;
    } catch (_) {
      // A missing mail app and a failed launch share the same fallback.
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No email app found. Write to $recipients.')),
      );
    }
  }

  Widget _developerCard(({String name, String email, String phone}) developer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE9E7F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            developer.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff29234B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 20,
                color: Color(0xff6F52E8),
              ),
              const SizedBox(width: 12),
              Expanded(child: SelectableText(developer.email)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 20,
                color: Color(0xff6F52E8),
              ),
              const SizedBox(width: 12),
              Expanded(child: SelectableText(developer.phone)),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xffF6F7FB),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'About Attendify',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Developed by',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                for (final developer in developers) ...[
                  _developerCard(developer),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Text(
                  'Contact both developers',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            _composeEmail(sheetContext, 'Attendify bug report'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(72),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          backgroundColor: const Color(0xff6F52E8),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bug_report_outlined, size: 21),
                            SizedBox(height: 4),
                            Text('Report a bug', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _composeEmail(
                          sheetContext,
                          'Attendify feature request',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(72),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          foregroundColor: const Color(0xff6F52E8),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 21),
                            SizedBox(height: 4),
                            Text(
                              'Request a feature',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'About Attendify and contact developers',
      icon: const Icon(Icons.info_outline_rounded, color: Colors.black87),
      onPressed: () => _showInfo(context),
    );
  }
}
