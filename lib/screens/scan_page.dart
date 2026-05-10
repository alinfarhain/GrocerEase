import 'package:flutter/material.dart';
import '../widgets/scan_page_popup.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ScanPagePopup(),
    );
  }
}
