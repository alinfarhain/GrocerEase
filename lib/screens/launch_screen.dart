import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() {
    return _LaunchScreenState();
  }
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void>? _checkStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.goNamed('onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFFF1F8E9),
              Color(0xFFFFFFFF),
              Color(0xFFFFF3E0),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: SizedBox(
                width: 120.0,
                height: 120.0,
                child: Image.asset(
                  'assets/GrocerEase Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            const Text(
              'GrocerEase',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF023047),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Plan smarter. Shop easier.',
              style: TextStyle(
                fontSize: 16.0,
                color: Color(0xFF5E6472),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48.0),
            const CircularProgressIndicator(
              strokeWidth: 3.0,
              color: Color(0xFFFFAB3F),
            ),
          ],
        ),
      ),
    );
  }
}
