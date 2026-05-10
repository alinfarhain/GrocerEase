import 'package:flutter/material.dart';
import 'onboarding_page_model.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.page, super.key});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    if (page.title.contains('Meal Planning')) {
      iconData = Icons.calendar_today_rounded;
      iconColor = const Color(0xFF1CB054);
    } else if (page.title.contains('Grocery Lists')) {
      iconData = Icons.shopping_cart_outlined;
      iconColor = const Color(0xFFFF8C00);
    } else if (page.title.contains('Pantry Tracking')) {
      iconData = Icons.inventory_2_outlined;
      iconColor = const Color(0xFF1CB054);
    } else {
      iconData = Icons.auto_awesome;
      iconColor = const Color(0xFFFF8C00);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                  const Color(0xFFFFF3E0).withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Icon(iconData, size: 64, color: iconColor),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF74777F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
