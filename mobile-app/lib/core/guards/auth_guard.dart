import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';
import '../../core/models/user_model.dart';
import '../../client/screens/client_navigation_wrapper.dart';
import '../../sales/screens/sales_navigation_wrapper.dart';
import '../../engineer/screens/engineer_navigation_wrapper.dart';
import '../notifications/notification_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService.isAuthenticated();
    if (token) {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _user = null;
          _isLoading = false;
        });
      }
    }
  }

  // Method to refresh auth state (called after login)
  void refresh() {
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      // Not authenticated, show login and cancel any engineer reminders.
      NotificationService.cancelEngineerDailyReportReminder();
      return widget.child;
    }

    // Authenticated, route based on role
    return _RouteBasedOnRole(user: _user!);
  }
}

class _RouteBasedOnRole extends StatelessWidget {
  final UserModel user;

  const _RouteBasedOnRole({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isClient) {
      // Ensure engineer reminders are not active for non-engineer roles.
      NotificationService.cancelEngineerDailyReportReminder();
      return ClientNavigationWrapper(user: user);
    } else if (user.isSales) {
      NotificationService.cancelEngineerDailyReportReminder();
      return SalesNavigationWrapper(user: user);
    } else if (user.isEngineer) {
      // Engineer: schedule daily report reminder check for today.
      NotificationService.scheduleEngineerDailyReportReminderIfNeeded();
      return EngineerNavigationWrapper(user: user);
    } else {
      // Unknown role - logout
      return const LoginScreen();
    }
  }
}

