import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import '../globals/app_state.dart';

class ProfileScreen extends StatefulWidget {
  final Function(AppCurrency) onCurrencyChanged;
  final Function(String) onDietaryChanged;

  const ProfileScreen({
    super.key,
    required this.onCurrencyChanged,
    required this.onDietaryChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _budget = 115.00;

  void _showCurrencyPicker() {
    final appState = AppState.of(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...AppCurrency.supported.map((c) {
              final isSelected = c.code == appState.currency.code;
              return ListTile(
                onTap: () {
                  widget.onCurrencyChanged(c);
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c.symbol.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                    ),
                  ),
                ),
                title: Text(
                  c.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _editBudget() {
    final appState = AppState.of(context, listen: false);
    final controller = TextEditingController(text: _budget.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: appState.currency.symbol,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _budget = double.tryParse(controller.text) ?? _budget);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDietaryPicker() {
    final appState = AppState.of(context, listen: false);
    final options = ['None', 'Vegetarian', 'Vegan', 'Halal', 'Pescatarian'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dietary Preference',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will flag items in your grocery list that conflict with this choice.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...options.map((o) => ListTile(
              title: Text(o),
              trailing: appState.dietaryPreference == o
                  ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                  : null,
              onTap: () {
                widget.onDietaryChanged(o);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(appState),
          const SizedBox(height: 24),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
          ),
          _buildMenuTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, size: 30, color: Color(0xFF2E7D32))),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('John Doe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('john.doe@example.com', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          _buildRowInfo('Currency', appState.currency.code, _showCurrencyPicker),
          _buildRowInfo('Budget', '${appState.currency.symbol}${_budget.toStringAsFixed(0)}', _editBudget),
          _buildRowInfo('Dietary', appState.dietaryPreference, _showDietaryPicker),
        ],
      ),
    );
  }

  Widget _buildRowInfo(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap, Color? textColor}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Terms and Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('1. Acceptance of Terms\nBy using GrocerEase, you agree to these terms...'),
          Text('\n2. Eligibility\nYou must be at least 13 years old...'),
          Text('\n3. Account Security\nYou are responsible for maintaining your account...'),
          Text('\n4. User Content\nYou retain ownership of data you enter...'),
          Text('\n5. Prohibited Conduct\nYou may not use the app for illegal purposes...'),
          Text('\n6. Payment & Subscriptions\nCertain features may require payment...'),
          Text('\n7. Dietary Disclaimer\nDietary warnings are for informational purposes only. Consult a professional...'),
          Text('\n8. Intellectual Property\nGrocerEase is owned by our company...'),
          Text('\n9. Limitation of Liability\nWe are not liable for any damages...'),
          Text('\n10. Termination\nWe may terminate your access at any time...'),
          Text('\n11. Governing Law\nThese terms are governed by the laws of Malaysia...'),
          Text('\n12. Changes to Terms\nWe may update these terms occasionally...'),
          Text('\n13. Contact\nSupport can be reached at support@grocerease.com'),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('1. Data Collection\nWe collect your email and usage data...'),
          Text('\n2. Use of Data\nTo improve your shopping experience...'),
          Text('\n3. Data Storage\nStored securely using Supabase with RLS...'),
          Text('\n4. Encryption\nSensitive data is encrypted with AES-256...'),
          Text('\n5. Data Sharing\nWe do not sell your data to third parties...'),
          Text('\n6. Cookies\nWe use essential session tokens only...'),
          Text('\n7. User Rights\nYou can request data deletion at any time...'),
          Text('\n8. Third Party Services\nWe use Supabase and Google Analytics...'),
          Text('\n9. Security Audits\nWe perform regular security checks...'),
          Text('\n10. Policy Updates\nLast updated: May 2024.'),
        ],
      ),
    );
  }
}
