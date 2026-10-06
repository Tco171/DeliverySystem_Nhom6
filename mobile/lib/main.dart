import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const ExpressApp());
}

class ExpressApp extends StatelessWidget {
  const ExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Express Delivery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123F31),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}