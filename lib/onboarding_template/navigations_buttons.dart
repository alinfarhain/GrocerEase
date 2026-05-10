import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  const NavigationButtons({
    required this.currentPageIndex,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    required this.onGetStarted,
    super.key,
  });

  final int currentPageIndex;

  final int totalPages;

  final void Function() onNext;

  final void Function() onSkip;

  final void Function() onGetStarted;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPageIndex == totalPages - 1;
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48, top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: isLastPage ? onGetStarted : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1CB054),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isLastPage) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
