// ─────────────────────────────────────────────
//  profile_screen.dart  (updated)
//  Fixes:
//   • UI redesigned to match target screenshot
//     (stats row, Quick Overview, green Settings button, Help & Support)
//   • TermsScreen — full 15-section content
//   • PrivacyScreen — full dummy content
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import '../globals/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════
//  ProfileScreen
// ═══════════════════════════════════════════════════════════
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
  bool _notificationsEnabled = true;

  // ── Pickers / dialogs ─────────────────────────────────────────────────

  void _showCurrencyPicker() {
    final appState = AppState.of(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            const Text('Select Currency',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...AppCurrency.supported.map((c) {
              final sel = c.code == appState.currency.code;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  widget.onCurrencyChanged(c);
                  Navigator.pop(ctx);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(c.symbol.trim(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel
                              ? const Color(0xFF2E7D32)
                              : Colors.black87)),
                ),
                title: Text(c.label,
                    style: TextStyle(
                        fontWeight:
                        sel ? FontWeight.w600 : FontWeight.w400)),
                trailing: sel
                    ? const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
      super.initState();
      _loadBudget();
    }

    Future<void> _loadBudget() async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        final row = await Supabase.instance.client
            .from('user_profiles')
            .select('budget, dietary_preference')
            .eq('id', userId)
            .maybeSingle();
        if (row != null && mounted) {
          setState(() {
            _budget = (row['budget'] as num?)?.toDouble() ?? 400.0;
          });
          final pref = row['dietary_preference'] as String?;
          if (pref != null && pref.isNotEmpty) {
            widget.onDietaryChanged(pref);
          }
        }
      } catch (_) {}
    }

  void _editBudget() {
    final appState = AppState.of(context, listen: false);
    final ctrl =
    TextEditingController(text: _budget.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: appState.currency.symbol,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newBudget = double.tryParse(ctrl.text) ?? _budget;
              setState(() => _budget = newBudget);
              Navigator.pop(ctx);
// Persist to Supabase
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                Supabase.instance.client
                    .from('user_profiles')
                    .update({'budget': newBudget})
                    .eq('id', userId)
                    .catchError((_) {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDietaryPicker() {
    final appState = AppState.of(context, listen: false);
    const options = [
      'None',
      'Vegetarian',
      'Vegan',
      'Halal',
      'Pescatarian'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            const Text('Dietary Preference',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
                'We will flag grocery items that conflict with your choice.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            ...options.map((o) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(o),
              trailing: appState.dietaryPreference == o
                  ? const Icon(Icons.check_circle,
                  color: Color(0xFF2E7D32))
                  : null,
              onTap: () {
                widget.onDietaryChanged(o);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  // ── Help dialog ───────────────────────────────────────────────────────
  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.help_outline,
                color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Help & Support'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with GrocerEase?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            _HelpRow(
                icon: Icons.email_outlined, text: 'grocerease@gmail.com'),
            SizedBox(height: 8),
            _HelpRow(
                icon: Icons.schedule_outlined,
                text: 'Mon – Fri, 9 am – 6 pm MYT'),
            SizedBox(height: 8),
            _HelpRow(
                icon: Icons.language_outlined,
                text: 'grocerease.app/support'),
            SizedBox(height: 16),
            Text(
                'We typically respond within 1 business day. '
                    'For urgent issues please email us directly.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text(
            'You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), // hook up real logout
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F0),
      appBar: AppBar(
        title: const Text('Profile',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ── Profile card ───────────────────────────────────────────
          _buildProfileCard(appState),
          const SizedBox(height: 20),

          // ── Quick Overview ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Quick Overview',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ),
          _buildQuickOverview(appState),
          const SizedBox(height: 16),

          // ── Settings (big green button) ────────────────────────────
          _buildSettingsButton(appState),
          const SizedBox(height: 12),

          // ── Menu tiles ─────────────────────────────────────────────
          _buildMenuCard([
            _menuRow(
              icon: Icons.security_outlined,
              label: 'Privacy & Security',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyScreen())),
            ),
            _divider(),
            _menuRow(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TermsScreen())),
            ),
            _divider(),
            _menuRow(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: _showHelp,
            ),
          ]),
          const SizedBox(height: 12),

          // ── Logout ─────────────────────────────────────────────────
          _buildMenuCard([
            _menuRow(
              icon: Icons.logout,
              label: 'Log out',
              onTap: _confirmLogout,
              labelColor: Colors.red,
              iconColor: Colors.red,
            ),
          ]),
        ],
      ),
    );
  }

  // ── Profile card (avatar + name + badge + stats) ──────────────────────
  Widget _buildProfileCard(AppState appState) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final fullName = (user?.userMetadata?['full_name'] as String?)
        ?.trim()
        .isNotEmpty == true
        ? user!.userMetadata!['full_name'] as String
        : email.split('@').first; // fallback to email username

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1B5E20),
              ),
              child: Center(
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(email,
                      style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF81C784), width: 1),
                    ),
                    child: const Text('GrocerEase Member',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Live stats from Supabase
          FutureBuilder<List<int>>(
            future: _fetchStats(),
            builder: (context, snap) {
              final recipesCount = snap.data?[0] ?? 0;
              final mealsPlanned = snap.data?[1] ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(recipesCount.toString(), 'Recipes'),
                  _statDivider(),
                  _statItem(mealsPlanned.toString(), 'Meals Planned'),
                  _statDivider(),
                  _statItem(
                      '${appState.currency.symbol.trim()}${_budget.toStringAsFixed(0)}',
                      'Budget'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<int>> _fetchStats() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [0, 0];
    try {
      final recipes = await Supabase.instance.client
          .from('recipes')
          .select('id')
          .eq('user_id', userId);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final meals = await Supabase.instance.client
          .from('meal_plans')
          .select('id')
          .eq('user_id', userId)
          .gte('planned_date',
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}')
          .lte('planned_date',
          '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}');
      return [(recipes as List).length, (meals as List).length];
    } catch (_) {
      return [0, 0];
    }
  }


  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
        width: 1, height: 36, color: Colors.grey.shade200);
  }

  // ── Quick Overview card ───────────────────────────────────────────────
  Widget _buildQuickOverview(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        // Monthly budget
        _overviewRow(
          iconBg: const Color(0xFFE8F5E9),
          icon: Icons.attach_money_rounded,
          iconColor: const Color(0xFF2E7D32),
          title: 'Monthly Budget',
          subtitle:
          '${appState.currency.symbol.trim()}${_budget.toStringAsFixed(0)}',
          trailing: GestureDetector(
            onTap: _editBudget,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 16, color: Colors.grey),
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100, indent: 60),
        // Dietary preferences
        _overviewRow(
          iconBg: const Color(0xFFFFF3E0),
          icon: Icons.language_outlined,
          iconColor: const Color(0xFFE65100),
          title: 'Dietary Preferences',
          subtitle: appState.dietaryPreference,
          trailing: const Icon(Icons.chevron_right,
              color: Colors.grey, size: 20),
          onTap: _showDietaryPicker,
        ),
        Divider(height: 1, color: Colors.grey.shade100, indent: 60),
        // Notifications
        _overviewRow(
          iconBg: const Color(0xFFFFF3E0),
          icon: Icons.notifications_outlined,
          iconColor: const Color(0xFFE65100),
          title: 'Notifications',
          subtitle: _notificationsEnabled ? 'All enabled' : 'Disabled',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            activeTrackColor: const Color(0xFF2E7D32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    );
  }

  Widget _overviewRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          trailing,
        ]),
      ),
    );
  }

  // ── Settings button (big green) ───────────────────────────────────────
  Widget _buildSettingsButton(AppState appState) {
    return GestureDetector(
      onTap: () => _showSettingsSheet(appState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Manage your preferences',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 22),
        ]),
      ),
    );
  }

  void _showSettingsSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            const Text('Settings',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _settingsTile(
              icon: Icons.currency_exchange,
              title: 'Currency',
              value: appState.currency.code,
              onTap: () {
                Navigator.pop(ctx);
                _showCurrencyPicker();
              },
            ),
            _settingsTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Monthly Budget',
              value:
              '${appState.currency.symbol.trim()}${_budget.toStringAsFixed(0)}',
              onTap: () {
                Navigator.pop(ctx);
                _editBudget();
              },
            ),
            _settingsTile(
              icon: Icons.restaurant_menu_outlined,
              title: 'Dietary Preference',
              value: appState.dietaryPreference,
              onTap: () {
                Navigator.pop(ctx);
                _showDietaryPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title:
      Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style:
              TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  // ── Menu card helper ──────────────────────────────────────────────────
  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 22),
      title: Text(label,
          style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 15)),
      trailing:
      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey.shade100, indent: 56);

  // ── Shared drag handle ────────────────────────────────────────────────
  Widget _dragHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2)),
    ),
  );
}

// ── Small helper widget used in dialog ───────────────────────────────────
class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelpRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 13)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  TermsScreen  — full 15-section content
// ═══════════════════════════════════════════════════════════
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Terms & Conditions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: const Color(0xFFCCE5CC), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Terms and Conditions for GrocerEase',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20))),
                const SizedBox(height: 6),
                Text('Last Updated: May 13, 2026',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                const Text(
                  'Welcome to GrocerEase. These Terms and Conditions govern your use of the GrocerEase mobile application. '
                      'By creating an account or using GrocerEase, you agree to these Terms.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section('1. About GrocerEase',
              'GrocerEase is a mobile application designed to assist users with:\n\n'
                  '• Meal planning\n'
                  '• Grocery list optimization\n'
                  '• Pantry tracking\n'
                  '• Budget tracking\n'
                  '• Basic health-related meal guidance\n\n'
                  'The application is intended for personal and non-commercial use only.'),
          _section('2. Eligibility',
              'You must be at least 7 years old to use GrocerEase.\n\n'
                  'If you are under the age of majority in your jurisdiction, you must use the application under the supervision of a parent or guardian.'),
          _section('3. User Accounts',
              'To access certain features, users must create an account using a valid email address and password.\n\n'
                  'You are responsible for:\n\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• All activities conducted under your account\n'
                  '• Providing accurate and updated information\n\n'
                  'You may delete your account at any time through the application settings or by contacting support.'),
          _section('4. Acceptable Use',
              'Users agree not to:\n\n'
                  '• Attempt to hack, disrupt, or damage the application\n'
                  '• Create fake or misleading accounts\n'
                  '• Upload offensive, abusive, harmful, or inappropriate content\n'
                  '• Use the application for unlawful purposes\n'
                  '• Interfere with other users\' experience\n\n'
                  'We reserve the right to suspend or permanently ban users who violate these Terms.'),
          _section('5. User Content',
              'Users may upload photos within the application.\n\n'
                  'You retain ownership of the content you upload. However, by uploading content, you grant GrocerEase a limited, non-exclusive right to store and display the content solely for operating the application.\n\n'
                  'We reserve the right to remove any content that violates these Terms or is considered inappropriate.'),
          _section('6. Privacy and Data Collection',
              'GrocerEase collects limited personal information, including:\n\n'
                  '• Name\n'
                  '• Email address\n\n'
                  'We do not collect:\n\n'
                  '• Payment information\n'
                  '• Phone numbers\n'
                  '• Location data\n\n'
                  'We do not sell or share your personal information with third parties.\n\n'
                  'GrocerEase uses Supabase services for backend functionality and analytics.\n\n'
                  'By using the application, you consent to the collection and use of information as described in our Privacy Policy.'),
          _section('7. Health-Related Information Disclaimer',
              'GrocerEase may provide meal planning suggestions, nutrition-related information, or general health guidance.\n\n'
                  'This information is provided for informational purposes only and does not constitute professional medical, dietary, or healthcare advice.\n\n'
                  'Users should consult qualified healthcare professionals before making significant dietary or health decisions.'),
          _section('8. Intellectual Property',
              'All application content, branding, logos, features, and software related to GrocerEase are owned by GrocerEase unless otherwise stated.\n\n'
                  'You may not:\n\n'
                  '• Copy\n'
                  '• Modify\n'
                  '• Reverse engineer\n'
                  '• Redistribute\n'
                  '• Commercially exploit\n\n'
                  'any part of the application without written permission.'),
          _section('9. Availability of Service',
              'We strive to keep GrocerEase available and functioning properly at all times. However, we do not guarantee uninterrupted or error-free operation.\n\n'
                  'The application is provided on an "as is" and "as available" basis.'),
          _section('10. Limitation of Responsibility',
              'While we aim to provide accurate and reliable services, GrocerEase is not responsible for:\n\n'
                  '• Data loss\n'
                  '• Inaccurate grocery or budget calculations\n'
                  '• User-generated content\n'
                  '• Service interruptions\n'
                  '• Technical errors\n\n'
                  'Users are responsible for verifying important information independently.'),
          _section('11. Account Suspension and Termination',
              'We reserve the right to suspend, restrict, or terminate accounts that:\n\n'
                  '• Violate these Terms\n'
                  '• Harm other users\n'
                  '• Abuse the platform\n'
                  '• Engage in suspicious or illegal activities\n\n'
                  'Termination may occur without prior notice.'),
          _section('12. Changes to These Terms',
              'We may update or modify these Terms at any time.\n\n'
                  'Updated Terms will become effective once posted within the application. Continued use of GrocerEase after updates constitutes acceptance of the revised Terms.'),
          _section('13. Governing Law',
              'These Terms shall be governed by and interpreted in accordance with the laws of Malaysia.\n\n'
                  'Any disputes arising from the use of GrocerEase shall be subject to the jurisdiction of the courts of Malaysia.'),
          _section('14. Contact Information',
              'For questions or support regarding these Terms, please contact:\n\n'
                  'Email: grocerease@gmail.com'),
          _section('15. Acceptance of Terms',
              'By creating an account or using GrocerEase, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.'),
          const SizedBox(height: 20),
          // Close button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('I Understand',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14, height: 1.6, color: Color(0xFF3D3D3D))),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PrivacyScreen  — full dummy content
// ═══════════════════════════════════════════════════════════
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: const Color(0xFFCCE5CC), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Privacy Policy for GrocerEase',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20))),
                const SizedBox(height: 6),
                Text('Last Updated: May 13, 2026',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                const Text(
                  'GrocerEase is committed to protecting your privacy. '
                      'This policy explains what information we collect, how we use it, and your rights.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section('1. Information We Collect',
              'GrocerEase collects only the minimum information necessary to operate the application:\n\n'
                  '• Name — used to personalise your experience\n'
                  '• Email address — used for account login and support\n\n'
                  'We do NOT collect:\n\n'
                  '• Payment or credit card details\n'
                  '• Phone numbers\n'
                  '• Precise or approximate location data\n'
                  '• Device contacts or call logs\n'
                  '• Biometric data'),
          _section('2. How We Use Your Information',
              'The information we collect is used solely to:\n\n'
                  '• Create and manage your GrocerEase account\n'
                  '• Provide and improve our features (meal planning, grocery lists, pantry tracking)\n'
                  '• Send important service notifications\n'
                  '• Respond to support requests\n'
                  '• Detect and prevent fraudulent or abusive behaviour'),
          _section('3. Data Storage and Infrastructure',
              'Your data is stored securely on Supabase, a cloud database platform. '
                  'Supabase applies Row Level Security (RLS) ensuring that each user can only access their own data.\n\n'
                  'Data is stored in servers located within regions compliant with applicable data protection laws.'),
          _section('4. Encryption and Security',
              'We apply the following security measures:\n\n'
                  '• Passwords are hashed using bcrypt before storage — we never store plain-text passwords\n'
                  '• All data in transit is encrypted using TLS 1.2 or higher\n'
                  '• Sensitive fields are encrypted at rest using AES-256\n'
                  '• Access tokens expire and are rotated regularly\n\n'
                  'While we take strong precautions, no system is 100% secure. '
                  'We encourage you to use a strong, unique password and enable any available two-factor options.'),
          _section('5. Data Sharing',
              'GrocerEase does NOT sell, rent, or trade your personal information.\n\n'
                  'We do not share your data with advertisers or third-party marketing services.\n\n'
                  'We may disclose information only in the following limited circumstances:\n\n'
                  '• When required by law or court order\n'
                  '• To protect the rights or safety of GrocerEase or its users\n'
                  '• With service providers (e.g. Supabase) strictly for operating the application — they are bound by confidentiality agreements'),
          _section('6. Cookies and Tracking',
              'GrocerEase uses only essential session tokens to keep you logged in.\n\n'
                  'We do NOT use:\n\n'
                  '• Advertising cookies\n'
                  '• Third-party tracking pixels\n'
                  '• Cross-site tracking\n\n'
                  'Any analytics collected are anonymised and aggregated — they cannot be used to identify individual users.'),
          _section('7. Your Rights',
              'You have the following rights regarding your personal data:\n\n'
                  '• Access — request a copy of the data we hold about you\n'
                  '• Correction — ask us to correct inaccurate information\n'
                  '• Deletion — request deletion of your account and all associated data\n'
                  '• Portability — request your data in a machine-readable format\n'
                  '• Objection — object to certain types of data processing\n\n'
                  'To exercise any of these rights, contact us at grocerease@gmail.com. '
                  'We will respond within 30 days.'),
          _section('8. Children\'s Privacy',
              'GrocerEase is not intended for children under 7 years old.\n\n'
                  'We do not knowingly collect personal information from children under 7. '
                  'If you believe your child has provided us with personal information, please contact us and we will delete it promptly.'),
          _section('9. Third-Party Services',
              'GrocerEase integrates with the following third-party service:\n\n'
                  '• Supabase (database and authentication) — subject to Supabase\'s own Privacy Policy\n\n'
                  'We are not responsible for the privacy practices of third-party websites or services linked from within the application.'),
          _section('10. Security Audits',
              'We conduct periodic internal security reviews to identify and address potential vulnerabilities.\n\n'
                  'Users are encouraged to report any suspected security issues to grocerease@gmail.com. '
                  'We take all reports seriously and aim to address confirmed issues within 72 hours.'),
          _section('11. Data Retention',
              'We retain your personal data for as long as your account is active.\n\n'
                  'If you delete your account:\n\n'
                  '• Your profile and associated data are permanently deleted within 30 days\n'
                  '• Anonymised, aggregated analytics data may be retained for service improvement\n\n'
                  'You may also request early deletion by contacting support.'),
          _section('12. Changes to This Policy',
              'We may update this Privacy Policy from time to time.\n\n'
                  'When we do, the "Last Updated" date at the top of this page will be revised. '
                  'For significant changes, we will notify you via the application.\n\n'
                  'Your continued use of GrocerEase after changes are posted constitutes acceptance of the updated Policy.'),
          _section('13. Contact Us',
              'If you have any questions, concerns, or requests regarding this Privacy Policy, please reach out:\n\n'
                  'Email: grocerease@gmail.com\n'
                  'Response time: within 1–2 business days\n'
                  'Support hours: Monday – Friday, 9 am – 6 pm MYT'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Close',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14, height: 1.6, color: Color(0xFF3D3D3D))),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade200),
        ],
      ),
    );
  }
}