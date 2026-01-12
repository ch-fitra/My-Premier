import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../shared/screens/profile_screen.dart';
import 'engineer_dashboard_screen.dart';
import 'engineer_reports_list_screen.dart';

class EngineerNavigationWrapper extends StatefulWidget {
  final UserModel user;

  const EngineerNavigationWrapper({
    super.key,
    required this.user,
  });

  @override
  State<EngineerNavigationWrapper> createState() =>
      _EngineerNavigationWrapperState();
}

class _EngineerNavigationWrapperState extends State<EngineerNavigationWrapper> {
  int _currentIndex = 0;

  final Color _primaryColor = Color(0xFF1A237E);
  final Color _accentColor = Color(0xFF3949AB);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF111827);
  final Color _textSecondary = Color(0xFF6B7280);
  final Color _borderColor = Color(0xFFE5E7EB);

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const EngineerDashboardScreen(),
      const EngineerReportsListScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 80, // Slightly taller for modern look
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                activeIcon: Icons.description_rounded,
                label: 'Reports',
                isActive: _currentIndex == 1,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentIndex == 2,
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        width: 72,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isActive ? _primaryColor.withOpacity(0.08) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isActive ? 32 : 24,
              height: isActive ? 32 : 24,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryColor, _accentColor],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? null
                    : Border.all(
                        color: _textSecondary.withOpacity(0.2),
                        width: 1.5,
                      ),
              ),
              child: Center(
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: isActive ? 18 : 20,
                  color: isActive ? Colors.white : _textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Animated label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _primaryColor : _textSecondary,
                letterSpacing: isActive ? 0.3 : 0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
