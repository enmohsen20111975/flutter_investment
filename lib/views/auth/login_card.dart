import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/common/section_card.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({
    required this.busy,
    required this.websiteUrl,
    required this.onGoogleSignIn,
    this.onForgotPassword,
    super.key,
  });

  final bool busy;
  final String websiteUrl;
  final Future<void> Function() onGoogleSignIn;
  final VoidCallback? onForgotPassword;

  Future<void> _openWebsite() async {
    final uri = Uri.parse(websiteUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'تسجيل الدخول',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('المتابعة باستخدام Google'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _openWebsite,
              icon: const Icon(Icons.language_outlined),
              label: const Text('فتح الموقع مباشرة'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: busy ? null : onForgotPassword,
              child: const Text('نسيت كلمة المرور؟'),
            ),
          ),
        ],
      ),
    );
  }
}
