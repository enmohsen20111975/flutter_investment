import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../config/theme.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
  }

  void _onIndexSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                context.watch<ThemeProvider>().isDarkMode
                    ? Icons.nightlight_round
                    : Icons.wb_sunny,
                color: Colors.white,
              ),
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 26),
              onPressed: () => context.push('/stocks'),
            ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 26),
                        onPressed: () => context.push('/alerts'),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        drawer: _buildDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: _buildScrollableBottomBar(isDark),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'الرئيسية';
      case 1:
        return 'الأسهم';
      case 2:
        return 'المعادن الثمينة';
      case 3:
        return 'المحفظة';
      case 4:
        return 'الدردشة الذكية';
      case 5:
        return 'المفضلة';
      case 6:
        return 'الإشعارات';
      case 7:
        return 'الإعدادات';
      default:
        return 'منصة EGX';
    }
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: Container(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: AppTheme.primaryColor,
              child: Column(
                 children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.account_circle, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'مرحباً بك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'حسابي',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    label: 'الرئيسية',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.show_chart_rounded,
                    label: 'الأسهم',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_rounded,
                    label: 'الذهب والفضة',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'المحفظة',
                    index: 3,
                  ),
                  _buildDrawerItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'الدردشة الذكية',
                    index: 4,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.star_border_rounded,
                    label: 'المفضلة',
                    index: 5,
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'الإشعارات',
                    index: 6,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'الإعدادات',
                    index: 7,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            SafeArea(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _currentIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : (isDark ? AppTheme.textPrimary : Colors.grey[700]),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : (isDark ? AppTheme.textPrimary : Colors.grey[700]),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isActive ? Icon(Icons.check_rounded, color: AppTheme.primaryColor, size: 20) : null,
      tileColor: isActive ? (isDark ? AppTheme.primary.withOpacity(0.1) : AppTheme.primary.withOpacity(0.05)) : null,
      onTap: () {
        Navigator.pop(context);
        _onIndexSelected(index);
      },
    );
  }

  Widget _buildScrollableBottomBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'الرئيسية',
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.show_chart_outlined,
                  activeIcon: Icons.show_chart_rounded,
                  label: 'الأسهم',
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: Icons.account_balance_outlined,
                  activeIcon: Icons.account_balance_rounded,
                  label: 'الذهب',
                  index: 2,
                ),
                _buildBottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'المحفظة',
                  index: 3,
                ),
                _buildBottomNavItem(
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy_rounded,
                  label: 'الدردشة',
                  index: 4,
                ),
                _buildBottomNavItem(
                  icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'المفضلة',
                  index: 5,
                ),
                _buildBottomNavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: 'الإشعارات',
                  index: 6,
                ),
                _buildBottomNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  index: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _currentIndex == index;
    final Color color = isActive ? AppTheme.primaryColor : (isDark ? AppTheme.textSecondary : Colors.grey[600]!);

    return InkWell(
      onTap: () => _onIndexSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppTheme.primary.withOpacity(0.15) : AppTheme.primary.withOpacity(0.08))
              : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: isActive ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
