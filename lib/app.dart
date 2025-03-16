import 'package:flutter/material.dart';
import 'main_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord Profil',
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF1A1B22)),
      home: const MainScreen(),
    );
  }
}