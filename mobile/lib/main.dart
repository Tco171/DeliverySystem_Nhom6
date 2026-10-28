import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/staff_home_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ExpressApp());
}

class ExpressApp extends StatefulWidget {
  const ExpressApp({super.key});

  @override
  State<ExpressApp> createState() => _ExpressAppState();
}

class _ExpressAppState extends State<ExpressApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final Future<Map<String, dynamic>?> _restoredSession;


  @override
  void initState() {
    super.initState();
    _restoredSession = ApiService.restoreSession();
    ApiService.onSessionExpired = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = navigatorKey.currentState;
        if (navigator == null || !navigator.mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      });
    };
  }

  @override
  void dispose() {
    ApiService.onSessionExpired = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Express Delivery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123F31),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _restoredSession,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null) return const HomePage();
          return (ApiService.currentRole == 'staff')
              ? StaffHomePage(user: user)
              : HomePage(user: user);
        },
      ),
    );
  }
}