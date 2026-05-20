import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/meal.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      children: [
        // Calendar Card
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF003D33)),
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
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF003D33)),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildWeekdayHeader(),
              const SizedBox(height: 12.0),
              _buildCalendarGrid(today),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _buildLegend(),
        const SizedBox(height: 24.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSelectedDayMeals(),
        const SizedBox(height: 100), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((d) => Text(d,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0, fontWeight: FontWeight.w500)))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday; // 1 = Monday, 7 = Sunday
    final List<Widget> dayWidgets = [];

    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final hasMeal = widget.mealPlan.containsKey(dateKey);
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
                        : (isSelected ? const Color(0xFFE8F5E9) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isSelected && !isToday
                        ? Border.all(color: const Color(0xFF1BAB52), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.white : const Color(0xFF003D33),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: hasMeal ? const Color(0xFF1BAB52) : Colors.transparent,
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
      childAspectRatio: 1.1, // Prevents excessive cell height
      children: dayWidgets,
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
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
                decoration: const BoxDecoration(color: Color(0xFF1BAB52), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8.0),
              const Text('Today', style: TextStyle(fontSize: 14.0, color: Color(0xFF003D33))),
            ],
          ),
          const SizedBox(width: 32.0),
          Row(
            children: [
              Container(
                width: 12.0,
                height: 4.0,
                decoration: BoxDecoration(
                    color: const Color(0xFF1BAB52), borderRadius: BorderRadius.circular(2.0)),
              ),
              const SizedBox(width: 8.0),
              const Text('Has meal', style: TextStyle(fontSize: 14.0, color: Color(0xFF003D33))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayMeals() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final meals = widget.mealPlan[dateKey] ?? [];

    if (meals.isEmpty) {
      return Container(
        height: 100.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const Text('No meal planned for this day', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: meals.asMap().entries.map((entry) {
        final meal = entry.value;
        final isFirst = entry.key == 0;
        final isLast = entry.key == meals.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineIndicator(isFirst, isLast),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[100]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (meal.originalData != null) {
                        context.pushNamed('recipe-view',
                            extra: Map<String, dynamic>.from(meal.originalData!));
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _getMealTypeBgColor(meal.mealType),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(meal.mealType.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _getMealTypeTextColor(meal.mealType))),
                            ),
                            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(meal.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D33))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${meal.servings}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 16),
                            const Icon(Icons.local_fire_department_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${meal.calories}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineIndicator(bool isFirst, bool isLast) {
    return SizedBox(
      width: 20,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!isLast)
            Positioned(
              top: 24,
              bottom: 0,
              child: Container(width: 1, color: Colors.grey[300]),
            ),
          if (!isFirst)
            Positioned(
              top: 0,
              height: 24,
              child: Container(width: 1, color: Colors.grey[300]),
            ),
          Positioned(
            top: 18,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealTypeBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return const Color(0xFFFFF3E0);
      case 'lunch': return const Color(0xFFE3F2FD);
      case 'dinner': return const Color(0xFFF3E5F5);
      case 'high tea': return const Color(0xFFE0F2F1);
      default: return const Color(0xFFF5F5F5);
    }
  }

  Color _getMealTypeTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return Colors.blue;
      case 'dinner': return Colors.purple;
      case 'high tea': return Colors.teal;
      default: return Colors.grey;
    }
  }
}