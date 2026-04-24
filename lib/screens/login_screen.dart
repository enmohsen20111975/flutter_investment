import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      _showErrorSnackbar(authProvider.error ?? 'حدث خطأ أثناء تسجيل الدخول');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC),
      body: Container(
        decoration: isDark
            ? null
            : BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppTheme.primary.withOpacity(0.05),
                    const Color(0xFFF8FAFC),
                  ],
                ),
              ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ──
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Title ──
                    Center(
                      child: Text(
                        'منصة EGX للاستثمار',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Section Title ──
                    Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بك مجدداً في منصة EGX',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isDark ? AppTheme.textSecondary : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Email Field ──
                    _buildTextFormField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'example@egx.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      validator: Validators.validateEmail,
                      enabled: !authProvider.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // ── Password Field ──
                    _buildTextFormField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: Validators.validatePassword,
                      enabled: !authProvider.isLoading,
                    ),
                    const SizedBox(height: 8),

                    // ── Forgot Password ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                // TODO: Navigate to forgot password
                              },
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Login Button ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primaryColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Divider with "أو" ──
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.textColor.withOpacity(0.15),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'أو',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textColor.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.textColor.withOpacity(0.15),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: 24),

                     // ── Google Sign In ──
                     SizedBox(
                       height: 52,
                       child: OutlinedButton.icon(
                         onPressed: authProvider.isLoading
                             ? null
                             : () async {
                                 final success = await authProvider.loginWithGoogle();
                                 if (!mounted) return;
                                 if (success) {
                                   context.go(AppRoutes.dashboard);
                                 }
                               },
                         icon: const Icon(Icons.login_rounded, size: 22),
                         label: const Text(
                           'تسجيل الدخول بحساب جوجل',
                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                         ),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: isDark ? Colors.white : Colors.black87,
                           backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                           side: BorderSide(
                             color: isDark ? Colors.white30 : Colors.grey.shade300,
                             width: 1.5,
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(14),
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(height: 8),

                     // ── Register Button ──
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => context.go(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: textDirection,
      validator: validator,
      enabled: enabled,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: textDirection,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.primary.withOpacity(0.5),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        labelStyle: TextStyle(
          color: isDark ? AppTheme.textSecondary : Colors.grey[600],
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.grey[400],
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
