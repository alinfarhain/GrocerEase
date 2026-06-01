import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/meal.dart';
import '../services/meal_plan_service.dart';

class MonthlyPage extends StatefulWidget {
  const MonthlyPage({
    required this.mealPlan,
    this.isEditing = false,
    this.onDeleteMeal,
    super.key,
  });

  /// Meals for the current week — passed from PlanPage (used as a fallback
  /// and for optimistic updates when editing from the weekly view).
  final Map<String, List<Meal>> mealPlan;
  final bool isEditing;
  final void Function(String dateKey)? onDeleteMeal;

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  // Self-fetched data for the displayed month (replaces widget.mealPlan for dots)
  Map<String, List<Meal>> _monthMealPlan = {};
  bool _isLoadingMonth = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
    _loadMonthData();
  }

  // ── DATA ─────────────────────────────────────────────────────────────────

  Future<void> _loadMonthData() async {
    setState(() => _isLoadingMonth = true);
    try {
      final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
      // Last day = day 0 of next month
      final lastDay =
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
      final plan = await MealPlanService.getMealPlansForRange(
        startDate: firstDay,
        endDate: lastDay,
      );
      if (mounted) {
        setState(() {
          _monthMealPlan = plan;
          _isLoadingMonth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMonth = false);
    }
  }

  /// Merged view: self-fetched month data takes precedence; widget.mealPlan
  /// fills in any keys not yet reflected in the fetched map (e.g. optimistic
  /// adds from the weekly view before a refresh).
  Map<String, List<Meal>> get _effectivePlan => {
    ...widget.mealPlan,
    ..._monthMealPlan,
  };

  void _previousMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteMealAt(String dateKey, int index) async {
    final meals = _effectivePlan[dateKey];
    if (meals == null || index >= meals.length) return;
    final meal = meals[index];

    // Optimistic remove from local map
    setState(() {
      final updated = List<Meal>.from(_monthMealPlan[dateKey] ?? meals);
      updated.removeAt(index);
      if (updated.isEmpty) {
        _monthMealPlan.remove(dateKey);
      } else {
        _monthMealPlan[dateKey] = updated;
      }
    });

    // Persist
    if (meal.id != null) {
      try {
        await MealPlanService.deleteMealPlan(meal.id!);
        // Also notify parent so weekly view stays in sync
        widget.onDeleteMeal?.call(dateKey);
      } catch (_) {
        // Rollback
        if (mounted) {
          setState(() {
            _monthMealPlan.putIfAbsent(dateKey, () => []).insert(index, meal);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to delete meal. Please try again.')),
          );
        }
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return RefreshIndicator(
      onRefresh: _loadMonthData,
      color: const Color(0xFF1BAB52),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        children: [
          // ── Calendar Card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                // Month header + chevrons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF003D33)),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Color(0xFF003D33)),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Day-of-week headers
                _buildWeekdayHeaders(),
                const SizedBox(height: 8.0),

                // Calendar grid (or loading spinner)
                _isLoadingMonth
                    ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1BAB52),
                      strokeWidth: 2,
                    ),
                  ),
                )
                    : _buildCalendarGrid(today),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // ── Legend ────────────────────────────────────────────────────
          _buildLegend(),

          const SizedBox(height: 24.0),

          // ── Selected Day Meals ────────────────────────────────────────
          _buildSelectedDayMeals(),

          const SizedBox(height: 100.0),
        ],
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildWeekdayHeaders() {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((d) => Text(
        d,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday; // 1 = Mon … 7 = Sun
    final List<Widget> dayWidgets = [];

    // Leading empty cells
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    final plan = _effectivePlan;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final hasMeal = plan.containsKey(dateKey); // ← now uses fetched data
      final isToday = date.isAtSameMomentAs(today);
      final isSelected = date.isAtSameMomentAs(_selectedDate);

      dayWidgets.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32.0,
                  height: 32.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF1BAB52)
                        : (isSelected
                        ? const Color(0xFFE8F5E9)
                        : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isSelected && !isToday
                        ? Border.all(
                        color: const Color(0xFF1BAB52), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isToday
                          ? Colors.white
                          : const Color(0xFF003D33),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: hasMeal
                        ? const Color(0xFF1BAB52)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      childAspectRatio: 1.1,
      children: dayWidgets,
    );
  }

  Widget _buildLegend() {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 10.0,
                height: 10.0,
                decoration: const BoxDecoration(
                    color: Color(0xFF1BAB52), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8.0),
              const Text('Today',
                  style: TextStyle(
                      fontSize: 14.0, color: Color(0xFF003D33))),
            ],
          ),
          const SizedBox(width: 32.0),
          Row(
            children: [
              Container(
                width: 12.0,
                height: 4.0,
                decoration: BoxDecoration(
                    color: const Color(0xFF1BAB52),
                    borderRadius: BorderRadius.circular(2.0)),
              ),
              const SizedBox(width: 8.0),
              const Text('Has meal',
                  style: TextStyle(
                      fontSize: 14.0, color: Color(0xFF003D33))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayMeals() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final meals = _effectivePlan[dateKey] ?? [];
    final formattedDate =
    DateFormat('EEEE, MMMM d').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003D33),
          ),
        ),
        const SizedBox(height: 12.0),
        if (meals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No meals planned',
                    style:
                    TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...meals.asMap().entries.map((entry) {
            final idx = entry.key;
            final meal = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  // Meal type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      meal.mealType,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1BAB52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Title
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (meal.originalData != null) {
                          context.pushNamed(
                            'recipe-view',
                            extra: Map<String, dynamic>.from(
                                meal.originalData!),
                          );
                        }
                      },
                      child: Text(
                        meal.title,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003D33),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Calories chip
                  if (meal.calories > 0) ...[
                    const SizedBox(width: 8.0),
                    Text(
                      '${meal.calories} cal',
                      style: const TextStyle(
                          fontSize: 12.0, color: Colors.grey),
                    ),
                  ],

                  // Delete button (only in editing mode)
                  if (widget.isEditing) ...[
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: () => _deleteMealAt(dateKey, idx),
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}