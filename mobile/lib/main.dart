import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/operations_home_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ExpressApp());
}

// Placeholder for StaffHomePage until staff module is merged
class StaffHomePage extends StatelessWidget {
  final Map<String, dynamic>? user;
  const StaffHomePage({super.key, this.user});

  @override
  Widget build(BuildContext context) => HomePage(user: user);
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
      home: FutureBuilder<Map<String, dynamic>?>(
        future: (ApiService.currentUserId != null || ApiService.currentToken != null)
            ? ApiService.getAccount()
            : Future.value(null),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (ApiService.currentRole == 'operations' || ApiService.currentRole == 'admin') {
            return OperationsHomePage(user: user);
          }
          return (ApiService.currentRole == 'staff')
              ? StaffHomePage(user: user)
              : HomePage(user: user);
        },
      ),
    );
  }
}
