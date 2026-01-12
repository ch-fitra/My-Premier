import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../shared/screens/profile_screen.dart';
import 'client_home_screen.dart';
import 'client_products_screen.dart';
import 'client_requests_list_screen.dart';
import 'client_support_list_screen.dart';

class ClientNavigationWrapper extends StatefulWidget {
  final UserModel user;

  const ClientNavigationWrapper({
    super.key,
    required this.user,
  });

  @override
  State<ClientNavigationWrapper> createState() => _ClientNavigationWrapperState();
}

class _ClientNavigationWrapperState extends State<ClientNavigationWrapper> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize screens here to have access to context and user
    final screens = [
      ClientHomeScreen(user: widget.user),
      const ClientProductsScreen(),
      const ClientRequestsListScreen(),
      const ClientSupportListScreen(),
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
            label: 'Support',
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

