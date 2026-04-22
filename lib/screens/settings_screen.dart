import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ─── Profile Section ───
            _SectionHeader(
              title: 'الملف الشخصي',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildProfileCard(context, user, isDark),

            const SizedBox(height: 28),

            // ─── Appearance Section ───
            _SectionHeader(
              title: 'المظهر',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildAppearanceCard(context, themeProvider, isDark),

            const SizedBox(height: 28),

            // ─── Notifications Section ───
            _SectionHeader(
              title: 'الإشعارات',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildNotificationsCard(context, isDark),

            const SizedBox(height: 28),

            // ─── General Section ───
            _SectionHeader(
              title: 'عام',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGeneralCard(context, isDark),

            const SizedBox(height: 28),

            // ─── Danger Zone ───
            _SectionHeader(
              title: '',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildLogoutButton(context, authProvider, isDark),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user, bool isDark) {
    final userData = user as Map<String, dynamic>?;
    final displayName = (userData?['name'] as String?) ?? 'مستخدم';
    final displayEmail = (userData?['email'] as String?) ?? 'user@egx.com';
    final firstLetter = displayName.isNotEmpty ? displayName[0] : 'م';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name & email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Edit button
            OutlinedButton(
              onPressed: () {
                context.push(AppRoutes.dashboard);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'تعديل',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, ThemeProvider provider, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'المظهر',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // Dark mode
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: provider.themeMode,
            onChanged: (value) => provider.setThemeMode(value!),
            title: const Text('داكن'),
            secondary: Icon(
              Icons.dark_mode_outlined,
              color: provider.themeMode == ThemeMode.dark
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Light mode
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: provider.themeMode,
            onChanged: (value) => provider.setThemeMode(value!),
            title: const Text('فاتح'),
            secondary: Icon(
              Icons.light_mode_outlined,
              color: provider.themeMode == ThemeMode.light
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // System mode
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: provider.themeMode,
            onChanged: (value) => provider.setThemeMode(value!),
            title: const Text('تلقائي (حسب النظام)'),
            secondary: Icon(
              Icons.brightness_auto_outlined,
              color: provider.themeMode == ThemeMode.system
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Column(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (value) {
              // TODO: implement notification toggle
            },
            title: Text(
              'إشعارات الأسعار',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'تلقي إشعارات عند تغير الأسعار',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            secondary: Icon(
              Icons.price_change_outlined,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            value: true,
            onChanged: (value) {
              // TODO: implement notification toggle
            },
            title: Text(
              'إشعارات الأخبار',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'تلقي إشعارات بأحدث أخبار البورصة',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            secondary: Icon(
              Icons.newspaper_outlined,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: 'اللغة',
            trailing: Text(
              'العربية',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            isDark: isDark,
            onTap: () {
              // TODO: language selection
            },
          ),
          const Divider(height: 1, indent: 52, endIndent: 16),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'المساعدة والدعم',
            trailing: Icon(
              Icons.chevron_left,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              size: 20,
            ),
            isDark: isDark,
            onTap: () {
              context.push(AppRoutes.dashboard);
            },
          ),
          const Divider(height: 1, indent: 52, endIndent: 16),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'حول التطبيق',
            trailing: Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            isDark: isDark,
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1, indent: 52, endIndent: 16),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'سياسة الخصوصية',
            trailing: Icon(
              Icons.chevron_left,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              size: 20,
            ),
            isDark: isDark,
            onTap: () {
              context.push(AppRoutes.dashboard);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider provider, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        color: Colors.red.shade50,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            Icons.logout,
            color: Colors.red.shade600,
          ),
          title: Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.red.shade700,
            ),
          ),
          onTap: () => _showLogoutConfirmation(context, provider),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.logout();
                context.go(AppRoutes.login);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AboutDialog(
          applicationName: 'EGX تداول',
          applicationVersion: '1.0.0',
          applicationIcon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.show_chart,
              color: Colors.white,
              size: 28,
            ),
          ),
          children: [
            const Text(
              'تطبيق تداول البورصة المصرية - EGX\nتابع أسعار الأسهم وأنشئ تنبيهات ذكية.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      leading: Icon(
        icon,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
