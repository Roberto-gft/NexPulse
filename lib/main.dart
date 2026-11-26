import 'package:flutter/material.dart';
import 'package:nexpulse/screens/login_screen.dart';
import 'package:nexpulse/utils/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadTheme();
  runApp(const NexPulseApp());
}

class NexPulseApp extends StatelessWidget {
  const NexPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'NexPulse',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E9E6B),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F8FA),
            cardColor: Colors.white,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CE0A3),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0E1416),
            cardColor: const Color(0xFF182226),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}