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

  final Map<String, List<Meal>> mealPlan;
  final bool isEditing;
  final void Function(String dateKey)? onDeleteMeal;

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

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

  // ── DATA ──────────────────────────────────────────────────────────────────

  Future<void> _loadMonthData() async {
    setState(() => _isLoadingMonth = true);
    try {
      final firstDay =
      DateTime(_currentMonth.year, _currentMonth.month, 1);
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

  // With confirmation dialog — for delete button taps
  Future<void> _deleteMealAt(String dateKey, int index) async {
    final meals = _effectivePlan[dateKey];
    if (meals == null || index >= meals.length) return;
    final meal = meals[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Meal'),
        content: Text(
            'Are you sure you want to delete "${meal.title}" from your plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteMealAtDirect(dateKey, index);
  }

  // Without dialog — for swipe after confirmDismiss
  Future<void> _deleteMealAtDirect(String dateKey, int index) async {
    final meals = _effectivePlan[dateKey];
    if (meals == null || index >= meals.length) return;
    final meal = meals[index];

    setState(() {
      final updated =
      List<Meal>.from(_monthMealPlan[dateKey] ?? meals);
      if (index < updated.length) updated.removeAt(index);
      if (updated.isEmpty) {
        _monthMealPlan.remove(dateKey);
      } else {
        _monthMealPlan[dateKey] = updated;
      }
    });

    if (meal.id != null) {
      try {
        await MealPlanService.deleteMealPlan(meal.id!);
        widget.onDeleteMeal?.call(dateKey);
      } catch (_) {
        if (mounted) {
          setState(() {
            _monthMealPlan
                .putIfAbsent(dateKey, () => [])
                .insert(index, meal);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                Text('Failed to delete meal. Please try again.')),
          );
        }
      }
    }
  }

  // ── EDIT ──────────────────────────────────────────────────────────────────

  Future<void> _editMealAt({
    required Meal meal,
    required String oldDateKey,
    required int index,
    required DateTime newDate,
    required String newCategory,
    String? newCustomCategory,
  }) async {
    if (meal.id == null) return;
    final newDateKey = DateFormat('yyyy-MM-dd').format(newDate);

    final updatedMeal = Meal(
      id: meal.id,
      title: meal.title,
      mealType: newCategory == 'Custom'
          ? (newCustomCategory?.isNotEmpty == true
          ? newCustomCategory!
          : 'Custom')
          : newCategory,
      customCategoryName:
      newCategory == 'Custom' ? newCustomCategory : null,
      servings: meal.servings,
      calories: meal.calories,
      originalData: meal.originalData,
    );

    setState(() {
      final oldList = _monthMealPlan[oldDateKey];
      if (oldList != null && index < oldList.length) {
        oldList.removeAt(index);
        if (oldList.isEmpty) _monthMealPlan.remove(oldDateKey);
      }
      _monthMealPlan
          .putIfAbsent(newDateKey, () => [])
          .add(updatedMeal);
      _selectedDate = newDate;
    });

    try {
      await MealPlanService.updateMealPlan(
        id: meal.id!,
        plannedDate: newDate,
        mealCategory: newCategory,
        customCategoryName:
        newCategory == 'Custom' ? newCustomCategory : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal plan updated!'),
            backgroundColor: Color(0xFF1BAB52),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _loadMonthData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Failed to update meal. Please try again.')),
        );
      }
    }
  }

  void _showEditMealSheet(Meal meal, String dateKey, int index) {
    DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(dateKey);
    final rawCategory =
    meal.customCategoryName != null ? 'Custom' : meal.mealType;
    String selectedCategory = rawCategory;
    final customCatController =
    TextEditingController(text: meal.customCategoryName ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF1BAB52)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text('Edit Meal Plan',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003D33))),
                                Text(meal.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              customCatController.dispose();
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100]),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Date',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF003D33))),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                    const ColorScheme.light(
                                        primary:
                                        Color(0xFF1BAB52)),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setModalState(
                                        () => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xFF1BAB52)),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF003D33)),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.edit_outlined,
                                      size: 16,
                                      color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('Meal Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF003D33))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              'Breakfast',
                              'Lunch',
                              'Dinner',
                              'High Tea',
                              'Custom',
                            ].map((cat) {
                              final isSelected =
                                  selectedCategory == cat;
                              return GestureDetector(
                                onTap: () => setModalState(
                                        () => selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.grey[100],
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1BAB52)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(Icons.check,
                                            size: 14,
                                            color: Color(0xFF1BAB52)),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(
                                                0xFF1BAB52)
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (selectedCategory == 'Custom') ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: customCatController,
                              decoration: InputDecoration(
                                hintText:
                                'e.g. Pre-workout, Supper...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ],
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                setModalState(
                                        () => isSaving = true);
                                final customName =
                                selectedCategory == 'Custom'
                                    ? customCatController
                                    .text
                                    .trim()
                                    : null;
                                customCatController.dispose();
                                Navigator.pop(context);
                                await _editMealAt(
                                  meal: meal,
                                  oldDateKey: dateKey,
                                  index: index,
                                  newDate: selectedDate,
                                  newCategory: selectedCategory,
                                  newCustomCategory: customName,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF1BAB52),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                                  : const Text('Update Plan',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Month navigation + calendar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF003D33)),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          minimumSize: const Size(40, 40)),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33)),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right,
                          color: Color(0xFF003D33)),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          minimumSize: const Size(40, 40)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWeekdayHeaders(),
                const SizedBox(height: 8),
                _isLoadingMonth
                    ? const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1BAB52),
                            strokeWidth: 2)))
                    : _buildCalendarGrid(today),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _buildLegend(),
          const SizedBox(height: 24.0),
          _buildSelectedDayMeals(),
          const SizedBox(height: 100.0),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((d) => Text(d,
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12.0,
              fontWeight: FontWeight.w500)))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday;
    final List<Widget> dayWidgets = [];

    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    final plan = _effectivePlan;

    for (int day = 1; day <= daysInMonth; day++) {
      final date =
      DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final hasMeal = plan.containsKey(dateKey);
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
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
                width: 10.0,
                height: 10.0,
                decoration: const BoxDecoration(
                    color: Color(0xFF1BAB52),
                    shape: BoxShape.circle)),
            const SizedBox(width: 8.0),
            const Text('Today',
                style: TextStyle(
                    fontSize: 14.0, color: Color(0xFF003D33))),
          ]),
          const SizedBox(width: 32.0),
          Row(children: [
            Container(
                width: 12.0,
                height: 4.0,
                decoration: BoxDecoration(
                    color: const Color(0xFF1BAB52),
                    borderRadius: BorderRadius.circular(2.0))),
            const SizedBox(width: 8.0),
            const Text('Has meal',
                style: TextStyle(
                    fontSize: 14.0, color: Color(0xFF003D33))),
          ]),
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
        Text(formattedDate,
            style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003D33))),
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
              child: Column(children: [
                Icon(Icons.restaurant_outlined,
                    size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('No meals planned',
                    style: TextStyle(
                        fontSize: 16.0, color: Colors.grey)),
              ]),
            ),
          )
        else
          ...meals.asMap().entries.map((entry) {
            final idx = entry.key;
            final meal = entry.value;
            return Dismissible(
              key: ValueKey(meal.id ?? '$dateKey-$idx'),
              direction: widget.isEditing
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 24),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Meal'),
                    content: Text(
                        'Are you sure you want to delete "${meal.title}" from your plan?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ??
                    false;
              },
              onDismissed: (_) => _deleteMealAtDirect(dateKey, idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(meal.categoryLabel,
                          style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1BAB52))),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isEditing &&
                              meal.originalData != null) {
                            context.pushNamed('recipe-view',
                                extra: Map<String, dynamic>.from(
                                    meal.originalData!));
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.title,
                                style: const TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF003D33)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            if (meal.calories > 0) ...[
                              const SizedBox(height: 2),
                              Text('${meal.calories} cal',
                                  style: const TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () =>
                            _showEditMealSheet(meal, dateKey, idx),
                        child: Container(
                          padding: const EdgeInsets.all(7.0),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius:
                              BorderRadius.circular(8.0)),
                          child: Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blue.shade400),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      GestureDetector(
                        onTap: () => _deleteMealAt(dateKey, idx),
                        child: Container(
                          padding: const EdgeInsets.all(7.0),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius:
                              BorderRadius.circular(8.0)),
                          child: Icon(Icons.delete_outline,
                              size: 16, color: Colors.red.shade400),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8.0),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}