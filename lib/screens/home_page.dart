import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildMealRow(String day, String meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 15.0, color: Color(0xFF003D33)),
        ),
        Text(
          meal,
          style: const TextStyle(
            fontSize: 15.0,
            color: Color(0xFF003D33),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertRow(String item, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          item,
          style: const TextStyle(fontSize: 15.0, color: Color(0xFF003D33)),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 15.0,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF1BAB52),
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 16.0),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  Text(
                    'RM285 of RM400 spent',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: 285 / 400,
              minHeight: 12.0,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1BAB52),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'RM115 remaining',
              style: TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => AppState.of(context, listen: false).setTabIndex(1),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF1BAB52),
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'This Week\'s Meals',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      Text(
                        '5 of 7 days planned',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Divider(height: 1.0),
          const SizedBox(height: 16.0),
          _buildMealRow('Monday', 'Pasta Primavera'),
          const SizedBox(height: 12.0),
          _buildMealRow('Tuesday', 'Chicken Stir-fry'),
          const SizedBox(height: 12.0),
          _buildMealRow('Wednesday', 'Veggie Tacos'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPantryAlertsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFFFEBEE)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => AppState.of(context, listen: false).setTabIndex(3),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF5350),
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                const Expanded(
                  child: Text(
                    'Pantry Alerts',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFEF5350)),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _buildAlertRow('Milk', 'Expires in 2 days', const Color(0xFFEF5350)),
          const SizedBox(height: 12.0),
          _buildAlertRow('Eggs', 'Running low', const Color(0xFFFF9800)),
          const SizedBox(height: 12.0),
          _buildAlertRow('Bread', 'Expires tomorrow', const Color(0xFFEF5350)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33),
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Here\'s your meal plan overview',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
              const SizedBox(height: 32.0),
              _buildMealsCard(context),
              const SizedBox(height: 20.0),
              _buildSummaryCard(
                context: context,
                icon: Icons.shopping_cart_outlined,
                iconColor: const Color(0xFFFF8A65),
                iconBgColor: const Color(0xFFFFF3E0),
                title: 'Grocery List',
                subtitle: '12 items remaining',
                onTap: () => AppState.of(context, listen: false).setTabIndex(2),
              ),
              const SizedBox(height: 20.0),
              _buildPantryAlertsCard(context),
              const SizedBox(height: 20.0),
              _buildBudgetCard(),
              const SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScanPage.show(context);
        },
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 28.0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
