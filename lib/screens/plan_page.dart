import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'monthly_page.dart';
import 'scan_page.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() {
    return _PlanPageState();
  }
}

class _PlanPageState extends State<PlanPage> {
  bool isMealPlanSelected = true;

  bool isWeeklyView = true;

  bool isEditing = false;

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  Map<String, dynamic> _mealPlan = {};

  final List<Map<String, dynamic>> _allRecipes = [
    {
      'id': 1,
      'name': 'Classic Margherita Pizza',
      'ingredients': [
        {'name': 'Pizza dough', 'amount': '1', 'unit': 'pack'},
        {'name': 'Tomato sauce', 'amount': '1/2', 'unit': 'cup'},
        {'name': 'Fresh mozzarella cheese', 'amount': '200', 'unit': 'g'},
        {'name': 'Fresh basil leaves', 'amount': '1', 'unit': 'handful'},
        {'name': 'Olive oil', 'amount': '2', 'unit': 'tbsp'},
        {'name': 'Salt and pepper to taste', 'amount': '', 'unit': ''},
      ],
      'instructions': [
        'Preheat the oven to 475°F (245°C).',
        'Roll out the pizza dough and spread tomato sauce evenly.',
        'Top with slices of fresh mozzarella and fresh basil leaves.',
        'Drizzle with olive oil and season with salt and pepper.',
        'Bake in the preheated oven for 12-15 minutes or until the crust is golden brown.',
        'Slice and serve hot.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Italian',
      'caloriesPerServing': 300,
      'tags': ['Pizza', 'Italian'],
      'userId': 166,
      'image': 'https://cdn.dummyjson.com/recipe-images/1.webp',
      'rating': 4.6,
      'reviewCount': 98,
      'mealType': ['Dinner'],
    },
    {
      'id': 2,
      'name': 'Vegetarian Stir-Fry',
      'ingredients': [
        {'name': 'Tofu, cubed', 'amount': '400', 'unit': 'g'},
        {'name': 'Broccoli florets', 'amount': '2', 'unit': 'cups'},
        {'name': 'Carrots, sliced', 'amount': '2', 'unit': 'pcs'},
        {'name': 'Bell peppers, sliced', 'amount': '2', 'unit': 'pcs'},
        {'name': 'Soy sauce', 'amount': '3', 'unit': 'tbsp'},
        {'name': 'Ginger, minced', 'amount': '1', 'unit': 'tsp'},
        {'name': 'Garlic, minced', 'amount': '2', 'unit': 'cloves'},
        {'name': 'Sesame oil', 'amount': '1', 'unit': 'tbsp'},
        {'name': 'Cooked rice for serving', 'amount': '2', 'unit': 'cups'},
      ],
      'instructions': [
        'In a wok, heat sesame oil over medium-high heat.',
        'Add minced ginger and garlic, sauté until fragrant.',
        'Add cubed tofu and stir-fry until golden brown.',
        'Add broccoli, carrots, and bell peppers. Cook until vegetables are tender-crisp.',
        'Pour soy sauce over the stir-fry and toss to combine.',
        'Serve over cooked rice.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 20,
      'servings': 3,
      'difficulty': 'Medium',
      'cuisine': 'Asian',
      'caloriesPerServing': 250,
      'tags': ['Vegetarian', 'Stir-fry', 'Asian'],
      'userId': 143,
      'image': 'https://cdn.dummyjson.com/recipe-images/2.webp',
      'rating': 4.7,
      'reviewCount': 26,
      'mealType': ['Lunch'],
    },
    {
      'id': 3,
      'name': 'Chocolate Chip Cookies',
      'ingredients': [
        {'name': 'All-purpose flour', 'amount': '2 1/4', 'unit': 'cups'},
        {'name': 'Butter, softened', 'amount': '1', 'unit': 'cup'},
        {'name': 'Brown sugar', 'amount': '3/4', 'unit': 'cup'},
        {'name': 'White sugar', 'amount': '3/4', 'unit': 'cup'},
        {'name': 'Eggs', 'amount': '2', 'unit': 'pcs'},
        {'name': 'Vanilla extract', 'amount': '1', 'unit': 'tsp'},
        {'name': 'Baking soda', 'amount': '1', 'unit': 'tsp'},
        {'name': 'Salt', 'amount': '1/2', 'unit': 'tsp'},
        {'name': 'Chocolate chips', 'amount': '2', 'unit': 'cups'},
      ],
      'instructions': [
        'Preheat the oven to 350°F (175°C).',
        'In a bowl, cream together softened butter, brown sugar, and white sugar.',
        'Beat in eggs one at a time, then stir in vanilla extract.',
        'Combine flour, baking soda, and salt. Gradually add to the wet ingredients.',
        'Fold in chocolate chips.',
        'Drop rounded tablespoons of dough onto ungreased baking sheets.',
        'Bake for 10-12 minutes or until edges are golden brown.',
        'Allow cookies to cool on the baking sheet for a few minutes before transferring to a wire rack.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 10,
      'servings': 24,
      'difficulty': 'Easy',
      'cuisine': 'American',
      'caloriesPerServing': 150,
      'tags': ['Cookies', 'Dessert', 'Baking'],
      'userId': 34,
      'image': 'https://cdn.dummyjson.com/recipe-images/3.webp',
      'rating': 4.9,
      'reviewCount': 13,
      'mealType': ['Snack', 'Dessert'],
    },
  ];

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
    });
  }

  void _deleteMeal(String dateKey) {
    setState(() {
      _mealPlan.remove(dateKey);
    });
  }

  Widget _buildMealCard(
      BuildContext context,
      DateTime date,
      Map<String, dynamic> recipeData,
      ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('d').format(date);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0.0, 4.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.0,
            height: 70.0,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF1BAB52),
                  ),
                ),
                Text(
                  dayNum,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1BAB52),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeData['name'] ?? 'Recipe',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${recipeData['servings'] ?? '4'}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${recipeData['caloriesPerServing'] ?? '450'}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isEditing)
            GestureDetector(
              onTap: () => _deleteMeal(dateKey),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF5350),
                  size: 20.0,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                context.pushNamed(
                  'recipe-view',
                  extra: Map<String, dynamic>.from(recipeData),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1BAB52),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(monday.year, monday.month, monday.day);
    _mealPlan.clear();
    for (int i = 0; i < 7; i++) {
      if (i != 1 && i != 5) {
        final date = _currentWeekStart.add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        if (i < _allRecipes.length) {
          _mealPlan[dateKey] = _allRecipes[i];
        }
      }
    }
  }

  Widget _buildMealPlanView(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekRange =
        '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final currentWeekOfToday = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final isThisWeek = _currentWeekStart.isAtSameMomentAs(currentWeekOfToday);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Plan',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    isWeeklyView ? 'Weekly view' : 'Monthly view',
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => isEditing = !isEditing),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? const Color(0xFF1BAB52)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEditing ? Icons.check : Icons.edit_outlined,
                        size: 18.0,
                        color: isEditing
                            ? Colors.white
                            : const Color(0xFF003D33),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        isEditing ? 'Done' : 'Edit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isEditing
                              ? Colors.white
                              : const Color(0xFF003D33),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Container(
            height: 44.0,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isWeeklyView = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isWeeklyView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16.0,
                            color: isWeeklyView
                                ? const Color(0xFF003D33)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Weekly',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isWeeklyView
                                  ? const Color(0xFF003D33)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isWeeklyView = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !isWeeklyView
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_view_month_outlined,
                            size: 16.0,
                            color: !isWeeklyView
                                ? const Color(0xFF003D33)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Monthly',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !isWeeklyView
                                  ? const Color(0xFF003D33)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          if (!isWeeklyView)
            MonthlyPage(
              mealPlan: _mealPlan,
              isEditing: isEditing,
              onDeleteMeal: (dateKey) => _deleteMeal(dateKey),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _changeWeek(-7),
                    child: const Row(
                      children: const [
                        Icon(Icons.chevron_left, color: Color(0xFF1BAB52)),
                        SizedBox(width: 4.0),
                        Text(
                          'Prev',
                          style: TextStyle(
                            color: Color(0xFF1BAB52),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        weekRange,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      Text(
                        isThisWeek ? 'This Week' : '',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _changeWeek(7),
                    child: const Row(
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Color(0xFF1BAB52),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.0),
                        Icon(Icons.chevron_right, color: Color(0xFF1BAB52)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            ...List.generate(7, (index) {
              final date = _currentWeekStart.add(Duration(days: index));
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final recipe = _mealPlan[dateKey];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: recipe != null
                    ? _buildMealCard(context, date, recipe)
                    : _buildEmptyDayCard(date),
              );
            }),
          ],
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  void _showEditMealSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Meal',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      DateFormat('EEE, MMM d').format(date),
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F8E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF003D33),
                      size: 20.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/my-recipes', extra: {'editMode': true});
                  },
                  borderRadius: BorderRadius.circular(20.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 56.0,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: const Icon(
                            Icons.book_outlined,
                            color: Color(0xFF1BAB52),
                            size: 28.0,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Select from Saved Recipes',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003D33),
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                'Choose from your saved recipes collection',
                                style: TextStyle(
                                  fontSize: 14.0,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayCard(DateTime date) {
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('d').format(date);
    return Container(
      height: 94.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
                Text(
                  dayNum,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          const Expanded(
            child: Text(
              'No meal planned',
              style: TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
          if (isEditing)
            GestureDetector(
              onTap: () => _showEditMealSheet(context, date),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF1BAB52),
                  size: 20.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Manage meals and recipes',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                  const SizedBox(height: 24.0),
                  Container(
                    height: 50.0,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4.0,
                                  offset: const Offset(0.0, 2.0),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Meal Plan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003D33),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('/my-recipes');
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'My Recipes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMealPlanView(context)),
          ],
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
    );
  }
}
