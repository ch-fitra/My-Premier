import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'core/guards/auth_guard.dart';
import 'core/notifications/notification_service.dart';
import 'core/splash_screen.dart';
import 'engineer/screens/engineer_create_report_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Premier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      initialRoute: '/',
      routes: {
        '/'      : (context) => const SplashScreen(),
        '/login': (context) => const AuthGuard(child: LoginScreen()),
        '/engineer/reports/create': (context) =>
            const EngineerCreateReportScreen(),
      },
    );
  }
}

