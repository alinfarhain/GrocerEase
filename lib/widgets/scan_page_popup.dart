import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/scan/scan_written_recipe_sheet.dart';

class ScanPagePopup extends StatelessWidget {
  const ScanPagePopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Smart Scan',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Choose what to scan',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF1BAB52),
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32.0),
          _buildScanOption(
            icon: Icons.camera_alt_outlined,
            title: 'Scan Meal or Ingredient',
            subtitle:
            'Get recipe recommendations by scanning a meal or ingredients',
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF1BAB52),
            onTap: () {
              Navigator.pop(context);       // close the bottom sheet first
              context.push('/scan-meal');   // then open the camera screen
            },
          ),
          const SizedBox(height: 16.0),
          _buildScanOption(
            icon: Icons.description_outlined,
            title: 'Scan Written Recipe',
            subtitle:
            'Extract recipe and grocery list from written recipes or URL website',
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF9800),
            onTap: () {
              Navigator.pop(context); // close Smart Scan sheet first
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ScanWrittenRecipeSheet(),
              );
            },
          ),
          const SizedBox(height: 16.0),
          _buildScanOption(
            icon: Icons.inventory_2_outlined,
            title: 'Scan Pantry or Barcode',
            subtitle:
            'Detect ingredients from pantry or barcode, and add them to your pantry inventory',
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF1BAB52),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required void Function() onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 28.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
