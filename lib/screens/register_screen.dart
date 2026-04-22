import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  // ── Password Strength ──
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
    });
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isLongEnough = password.length >= 8;

    if (isLongEnough && hasUppercase && hasLowercase && hasNumbers && hasSpecial) {
      return PasswordStrength.strong;
    } else if (isLongEnough && (hasUppercase || hasNumbers)) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  Color _getStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.amber;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthLabel() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 'ضعيفة';
      case PasswordStrength.medium:
        return 'متوسطة';
      case PasswordStrength.strong:
        return 'قوية';
    }
  }

  double _getStrengthValue() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showErrorSnackbar('يجب الموافقة على الشروط والأحكام');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      _showErrorSnackbar(authProvider.error ?? 'حدث خطأ أثناء إنشاء الحساب');
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.textColor,
          ),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ──
                  Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أنشئ حسابك وابدأ الاستثمار في البورصة المصرية',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Name Field ──
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    hint: 'محمد أحمد علي',
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateName,
                    enabled: !authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

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

                  // ── Phone Field ──
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    hint: '01XXXXXXXXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    validator: Validators.validatePhone,
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
                        color: AppTheme.textColor.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(
                            () => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: Validators.validatePassword,
                    enabled: !authProvider.isLoading,
                  ),

                  // ── Password Strength Indicator ──
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPasswordStrengthIndicator(),
                  ],
                  const SizedBox(height: 16),

                  // ── Confirm Password Field ──
                  _buildTextFormField(
                    controller: _confirmPasswordController,
                    label: 'تأكيد كلمة المرور',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textColor.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    enabled: !authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // ── Terms Checkbox ──
                  Theme(
                    data: ThemeData(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.primaryColor;
                          }
                          return Colors.transparent;
                        }),
                        side: BorderSide(
                          color: _acceptedTerms
                              ? AppTheme.primaryColor
                              : AppTheme.textColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: authProvider.isLoading
                              ? null
                              : (value) {
                                  setState(() =>
                                      _acceptedTerms = value ?? false);
                                },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: authProvider.isLoading
                                ? null
                                : () {
                                    setState(() =>
                                        _acceptedTerms = !_acceptedTerms);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  text: 'أوافق على ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textColor
                                        .withValues(alpha: 0.7),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'الشروط والأحكام',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Register Button ──
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.5),
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
                              'إنشاء الحساب',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Login Link ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب؟',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => context.go(AppRoutes.login),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Password Strength Indicator ──
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'قوة كلمة المرور',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              _getStrengthLabel(),
              style: TextStyle(
                fontSize: 12,
                color: _getStrengthColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _getStrengthValue(),
            backgroundColor: AppTheme.textColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
            minHeight: 4,
          ),
        ),
      ],
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: textDirection,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: textDirection,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.textColor.withValues(alpha: 0.5),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        labelStyle: TextStyle(
          color: AppTheme.textColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: AppTheme.textColor.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.textColor.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: TextStyle(
          color: Colors.red.shade600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Password Strength Enum ──
enum PasswordStrength { weak, medium, strong }
