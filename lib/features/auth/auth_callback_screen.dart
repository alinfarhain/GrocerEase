import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown briefly while the deep link auth callback is being processed.
/// The DeepLinkService will navigate away once the session is confirmed.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  /// If the session is already established (handler already ran), redirect now.
  void _checkExistingSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Verifying your email…',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}