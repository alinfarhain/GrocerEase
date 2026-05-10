import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigatePage extends StatelessWidget {
  const NavigatePage({super.key});

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
            colors: [
              Color(0xFFF1F8E9),
              Color(0xFFFFFFFF),
              Color(0xFFFFF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  width: 140.0,
                  height: 140.0,
                  child: Image.asset(
                    'assets/GrocerEase Logo.png',
                    fit: BoxFit.contain,
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
                const SizedBox(height: 16.0),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Your all-in-one solution for meal planning, smart grocery lists, and pantry management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFF5E6472),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    onPressed: () => context.pushNamed('register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B9E56),
                      foregroundColor: Colors.white,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: OutlinedButton(
                    onPressed: () => context.pushNamed('login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF023047),
                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
