import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'home_page.dart';
import 'plan_page.dart';
import 'pantry_page.dart';
import 'grocery_list_screen.dart';
import 'profile_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _pages = [
    const HomePage(),
    const PlanPage(),
    const GroceryListScreen(),
    const PantryPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    return Scaffold(
      body: IndexedStack(
        index: appState.currentTabIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.0,
              offset: const Offset(0.0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1BAB52),
          unselectedItemColor: Colors.grey,
          currentIndex: appState.currentTabIndex,
          onTap: (index) {
            appState.setTabIndex(index);
          },
          selectedLabelStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Plan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Pantry',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
