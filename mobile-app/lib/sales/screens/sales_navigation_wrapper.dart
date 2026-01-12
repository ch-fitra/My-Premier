import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../shared/screens/profile_screen.dart';
import 'sales_dashboard_screen.dart';
import 'sales_products_screen.dart';
import 'sales_requests_list_screen.dart';
import 'sales_support_list_screen.dart';

class SalesNavigationWrapper extends StatefulWidget {
  final UserModel user;

  const SalesNavigationWrapper({
    super.key,
    required this.user,
  });

  @override
  State<SalesNavigationWrapper> createState() => _SalesNavigationWrapperState();
}

class _SalesNavigationWrapperState extends State<SalesNavigationWrapper> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SalesDashboardScreen(),
      const SalesProductsScreen(),
      const SalesRequestsListScreen(),
      const SalesSupportListScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outlined),
            selectedIcon: Icon(Icons.mail),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Supports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

