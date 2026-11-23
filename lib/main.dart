import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'screens/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  ApiClient.onUnauthorized = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Attendance',

      home: const SplashScreen(),

      routes: {
        '/signup': (_) => const LoginScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
