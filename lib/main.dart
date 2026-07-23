import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const EasyDocsApp());
}

class EasyDocsApp extends StatelessWidget {
  const EasyDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "EasyDocs",

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFE8F2FF),
          background: const Color(0xFFE8F2FF),
          surfaceVariant: const Color(0xFFDCE7FF),
        ),
        useMaterial3: true,
      ),

      home: const HomeScreen(),
    );
  }
}