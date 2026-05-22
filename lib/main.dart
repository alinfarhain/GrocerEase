import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals/router.dart';
import 'globals/app_state.dart';
import 'integrations/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/deep_link_service.dart';

late SharedPreferences sharedPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://cgosdfzvwhelfexdovry.supabase.co',   // ← replace
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb3NkZnp2d2hlbGZleGRvdnJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTU4OTgsImV4cCI6MjA5MzQ3MTg5OH0.FXcbpyTn4KqalmYe-00ibCHBYM1l5A6zZIvvWudSTsc',                      // ← replace
  );

  // Initialize SharedPreferences
  sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Supabase
  await SupabaseService().initialize();

  // Set status bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const GroceryApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class GroceryApp extends StatefulWidget {
  const GroceryApp({super.key});

  @override
  State<GroceryApp> createState() => _GroceryAppState();
}

class _GroceryAppState extends State<GroceryApp> {

  @override
  void initState() {
    super.initState();
    _initDeepLinks(); // ✅ ADD: start listening for deep links
  }

  void _initDeepLinks() {
    DeepLinkService().initialize(
      onAuthenticated: () {
        // appRouter is your GoRouter instance from globals/router.dart
        // Adjust the route path to match whatever your home route is called
        appRouter.go('/home');
      },
      onVerificationFailed: () {
        // Optional: go to login with an error message
        appRouter.go('/login');
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService().dispose(); // ✅ ADD: cancel the stream subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GrocerEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
