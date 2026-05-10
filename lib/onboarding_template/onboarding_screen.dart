import 'package:flutter/material.dart';
import 'onboarding_page_model.dart';
import 'onboarding_page.dart';
import 'onboarding_indicator.dart';
import 'navigations_buttons.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() {
    return _OnboardingScreenState();
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPageIndex = 0;

  final List<OnboardingPageModel> _pages = [
    const OnboardingPageModel(
      title: 'Meal Planning Made Simple',
      description:
      'Organise your weekly meals effortlessly with smart recipe suggestions tailored to your preferences and schedule.',
      imagePath:
      'https://images.unsplash.com/photo-1543353071-10c8ba85a902?w=400&h=400&fit=crop',
    ),
    const OnboardingPageModel(
      title: 'Smart Grocery Lists & Budget Control',
      description:
      'Automatically generate grocery lists from your meal plans and track your spending with real-time budget monitoring.',
      imagePath:
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&h=400&fit=crop',
    ),
    const OnboardingPageModel(
      title: 'Pantry Tracking & Smart Scanning',
      description:
      'Keep track of what you have, get expiry alerts, and scan items or recipes instantly with your camera.',
      imagePath:
      'https://images.unsplash.com/photo-1583258292688-d5bec682b811?w=400&h=400&fit=crop',
    ),
    const OnboardingPageModel(
      title: 'All-in-One Convenience',
      description:
      'Everything you need to plan meals, manage groceries, and reduce food waste—all in one place.',
      imagePath:
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=400&h=400&fit=crop',
    ),
  ];

  void goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipToLastPage() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, top: 16.0),
                child: GestureDetector(
                  onTap: skipToLastPage,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFF707781),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    OnboardingPage(page: _pages[index]),
              ),
            ),
            OnboardingIndicator(
              controller: _pageController,
              count: _pages.length,
              activeIndex: _currentPageIndex,
            ),
            NavigationButtons(
              currentPageIndex: _currentPageIndex,
              totalPages: _pages.length,
              onNext: goToNextPage,
              onSkip: skipToLastPage,
              onGetStarted: navigateToHome,
            ),
          ],
        ),
      ),
    );
  }

  void navigateToHome() {
    final appState = AppState.of(context, listen: false);
    appState.setFirstTime(false);
    context.goNamed('navigate');
  }
}
