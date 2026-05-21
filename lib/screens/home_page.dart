import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../globals/app_state.dart';
import 'scan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  // Real data from Supabase
  int _groceryItemsRemaining = 0;
  double _budgetSpent = 0;
  double _budget = 400;
  List<Map<String, dynamic>> _thisWeekMeals = [];
  List<Map<String, dynamic>> _expiringItems = [];
  int _daysPlanned = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      // Run all queries concurrently
      final results = await Future.wait([
        _fetchGrocerySummary(userId),
        _fetchBudget(userId),
        _fetchThisWeekMeals(userId),
        _fetchExpiringPantryItems(userId),
      ]);
      if (mounted) {
        setState(() {
          _groceryItemsRemaining = results[0] as int;
          final budgetData = results[1] as Map<String, double>;
          _budget = budgetData['budget']!;
          _budgetSpent = budgetData['spent']!;
          _thisWeekMeals = results[2] as List<Map<String, dynamic>>;
          _expiringItems = results[3] as List<Map<String, dynamic>>;
          _daysPlanned = _thisWeekMeals
              .map((m) => m['planned_date'] as String)
              .toSet()
              .length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _fetchGrocerySummary(String userId) async {
    final rows = await Supabase.instance.client
        .from('grocery_items')
        .select('id, is_checked')
        .eq('user_id', userId);
    return (rows as List).where((r) => r['is_checked'] == false).length;
  }

  Future<Map<String, double>> _fetchBudget(String userId) async {
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('budget')
        .eq('id', userId)
        .maybeSingle();
    final budget = (profile?['budget'] as num?)?.toDouble() ?? 400.0;

    // Sum price of checked (purchased) grocery items as "spent"
    final checkedItems = await Supabase.instance.client
        .from('grocery_items')
        .select('price')
        .eq('user_id', userId)
        .eq('is_checked', true);
    final spent = (checkedItems as List)
        .fold(0.0, (s, r) => s + ((r['price'] as num?)?.toDouble() ?? 0));
    return {'budget': budget, 'spent': spent};
  }

  Future<List<Map<String, dynamic>>> _fetchThisWeekMeals(
      String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = (DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final rows = await Supabase.instance.client
        .from('meal_plans')
        .select('planned_date, recipe_name, meal_category')
        .eq('user_id', userId)
        .gte('planned_date', fmt(weekStart))
        .lte('planned_date', fmt(weekEnd))
        .order('planned_date');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> _fetchExpiringPantryItems(
      String userId) async {
    final today = DateTime.now();
    final in7Days = today.add(const Duration(days: 7));
    final fmt = (DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final rows = await Supabase.instance.client
        .from('pantry_items')
        .select('name, expiry_date, quantity')
        .eq('user_id', userId)
        .lte('expiry_date', fmt(in7Days))
        .order('expiry_date');
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildMealRow(String day, String meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day,
            style:
            const TextStyle(fontSize: 15.0, color: Color(0xFF003D33))),
        Text(meal,
            style: const TextStyle(
                fontSize: 15.0,
                color: Color(0xFF003D33),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertRow(String item, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(item,
            style:
            const TextStyle(fontSize: 15.0, color: Color(0xFF003D33))),
        Text(status,
            style: TextStyle(
                fontSize: 15.0,
                color: statusColor,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _expiryLabel(String? expiryStr) {
    if (expiryStr == null) return 'No expiry';
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return 'No expiry';
    final diff = expiry
        .difference(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    return 'Expires in $diff day${diff == 1 ? '' : 's'}';
  }

  Color _expiryColor(String? expiryStr) {
    if (expiryStr == null) return Colors.grey;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return Colors.grey;
    final diff = expiry
        .difference(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    if (diff < 0) return const Color(0xFFEF5350);
    if (diff <= 2) return const Color(0xFFEF5350);
    if (diff <= 7) return const Color(0xFFFF9800);
    return Colors.grey;
  }

  String _weekdayName(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[(d.weekday - 1).clamp(0, 6)];
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _buildBudgetCard() {
    final remaining = _budget - _budgetSpent;
    final progress = _budget > 0 ? (_budgetSpent / _budget).clamp(0.0, 1.0) : 0.0;
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(Icons.attach_money,
                  color: Color(0xFF1BAB52), size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Budget',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33))),
                Text(
                  'RM${_budgetSpent.toStringAsFixed(0)} of RM${_budget.toStringAsFixed(0)} spent',
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12.0,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF1BAB52),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              remaining >= 0
                  ? 'RM${remaining.toStringAsFixed(0)} remaining'
                  : 'RM${(-remaining).toStringAsFixed(0)} over budget',
              style: TextStyle(
                  fontSize: 14.0,
                  color: remaining < 0 ? Colors.red : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsCard(BuildContext context) {
    final previewMeals = _thisWeekMeals.take(3).toList();
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
            onTap: () =>
                AppState.of(context, listen: false).setTabIndex(1),
            behavior: HitTestBehavior.opaque,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(Icons.calendar_month,
                    color: Color(0xFF1BAB52), size: 24.0),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("This Week's Meals",
                        style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33))),
                    Text(
                      '$_daysPlanned of 7 days planned',
                      style: const TextStyle(
                          fontSize: 14.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
          if (previewMeals.isNotEmpty) ...[
            const SizedBox(height: 20.0),
            const Divider(height: 1.0),
            const SizedBox(height: 16.0),
            ...previewMeals.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildMealRow(
                _weekdayName(m['planned_date'] as String? ?? ''),
                m['recipe_name'] as String? ?? 'Untitled',
              ),
            )),
          ] else ...[
            const SizedBox(height: 16),
            const Text('No meals planned this week yet.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
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
        child: Row(children: [
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33))),
                Text(subtitle,
                    style:
                    const TextStyle(fontSize: 14.0, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildPantryAlertsCard(BuildContext context) {
    if (_expiringItems.isEmpty) return const SizedBox.shrink();
    final preview = _expiringItems.take(3).toList();
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
            onTap: () =>
                AppState.of(context, listen: false).setTabIndex(3),
            behavior: HitTestBehavior.opaque,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(Icons.error_outline,
                    color: Color(0xFFEF5350), size: 24.0),
              ),
              const SizedBox(width: 16.0),
              const Expanded(
                child: Text('Pantry Alerts',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF5350))),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFEF5350)),
            ]),
          ),
          const SizedBox(height: 16.0),
          ...preview.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildAlertRow(
              item['name'] as String? ?? '',
              _expiryLabel(item['expiry_date'] as String?),
              _expiryColor(item['expiry_date'] as String?),
            ),
          )),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName =
        (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    final greeting =
    fullName.isNotEmpty ? 'Welcome, $fullName!' : 'Welcome!';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: const Color(0xFF1BAB52),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33))),
                const SizedBox(height: 8.0),
                const Text("Here's your meal plan overview",
                    style: TextStyle(fontSize: 16.0, color: Colors.grey)),
                const SizedBox(height: 32.0),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(
                          color: Color(0xFF1BAB52)),
                    ),
                  )
                else ...[
                  _buildMealsCard(context),
                  const SizedBox(height: 20.0),
                  _buildSummaryCard(
                    context: context,
                    icon: Icons.shopping_cart_outlined,
                    iconColor: const Color(0xFFFF8A65),
                    iconBgColor: const Color(0xFFFFF3E0),
                    title: 'Grocery List',
                    subtitle: '$_groceryItemsRemaining items remaining',
                    onTap: () =>
                        AppState.of(context, listen: false).setTabIndex(2),
                  ),
                  const SizedBox(height: 20.0),
                  if (_expiringItems.isNotEmpty)
                    _buildPantryAlertsCard(context),
                  if (_expiringItems.isNotEmpty)
                    const SizedBox(height: 20.0),
                  _buildBudgetCard(),
                  const SizedBox(height: 100.0),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScanPage.show(context),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28.0),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}