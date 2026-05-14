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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildLegend(today),
        const SizedBox(height: 24.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate),
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSelectedMealCard(),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12.0, fontWeight: FontWeight.w500)))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday;
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
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isToday)
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: const BoxDecoration(color: Color(0xFF1BAB52), shape: BoxShape.circle),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.white : (isSelected ? const Color(0xFF1BAB52) : const Color(0xFF003D33)),
                      ),
                    ),
                    if (hasMeal)
                      Container(
                        margin: const EdgeInsets.only(top: 2.0),
                        width: 4.0,
                        height: 4.0,
                        decoration: const BoxDecoration(color: Color(0xFF1BAB52), shape: BoxShape.circle),
                      ),
                  ],
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
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      children: dayWidgets,
    );
  }

  Widget _buildLegend(DateTime today) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(const Color(0xFF1BAB52), 'Today', isCircle: true),
          const SizedBox(width: 24.0),
          _legendItem(const Color(0xFF1BAB52), 'Has meal', isCircle: false),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool isCircle}) {
    return Row(
      children: [
        Container(
          width: isCircle ? 12.0 : 8.0,
          height: isCircle ? 12.0 : 4.0,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(label, style: const TextStyle(fontSize: 14.0, color: Color(0xFF003D33))),
      ],
    );
  }

  Widget _buildSelectedMealCard() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final meals = widget.mealPlan[dateKey];
    
    if (meals == null || meals.isEmpty) {
      return Container(
        height: 100.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const Text('No meal planned for this day', style: TextStyle(color: Colors.grey)),
      );
    }
    
    final meal = meals.first;
    final dayName = DateFormat('EEE').format(_selectedDate);
    final dayNum = DateFormat('d').format(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 2.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8.0, offset: const Offset(0.0, 4.0))],
      ),
      child: Row(
        children: [
          Container(
            width: 60.0,
            height: 70.0,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayName, style: const TextStyle(fontSize: 12.0, color: Color(0xFF1BAB52))),
                Text(dayNum, style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF1BAB52))),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.title, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF003D33))),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text('${meal.servings}', style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                    const SizedBox(width: 16.0),
                    const Icon(Icons.local_fire_department_outlined, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text('${meal.calories}', style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.isEditing)
            GestureDetector(
              onTap: () => widget.onDeleteMeal?.call(dateKey),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 20.0),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (meal.originalData != null) {
                  context.pushNamed('recipe-view', extra: Map<String, dynamic>.from(meal.originalData!));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: Color(0xFF1BAB52)),
              ),
            ),
        ],
      ),
    );
  }
}
