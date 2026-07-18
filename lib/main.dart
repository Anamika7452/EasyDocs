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
        ),
        useMaterial3: true,
      ),

      home: const HomeScreen(),
    );
  }
}