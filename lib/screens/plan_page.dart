import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'monthly_page.dart';
import 'scan_page.dart';
import '../models/meal.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool isWeeklyView = true;
  bool isEditing = false;

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  final Map<String, List<Meal>> _mealPlan = <String, List<Meal>>{};

  final List<Map<String, dynamic>> _savedRecipes = [
    {
      "id": 1,
      "name": "Classic Margherita Pizza",
      "ingredients": ["Pizza dough", "Tomato sauce", "Fresh mozzarella cheese", "Fresh basil leaves", "Olive oil", "Salt and pepper to taste"],
      "instructions": ["Preheat the oven to 475°F (245°C).", "Roll out the pizza dough and spread tomato sauce evenly.", "Top with slices of fresh mozzarella and fresh basil leaves.", "Drizzle with olive oil and season with salt and pepper.", "Bake in the preheated oven for 12-15 minutes or until the crust is golden brown.", "Slice and serve hot."],
      "prepTimeMinutes": 20,
      "cookTimeMinutes": 15,
      "servings": 4,
      "difficulty": "Easy",
      "cuisine": "Italian",
      "caloriesPerServing": 300,
      "image": "https://cdn.dummyjson.com/recipe-images/1.webp",
      "mealType": ["Dinner"]
    },
    {
      "id": 2,
      "name": "Vegetarian Stir-Fry",
      "ingredients": ["Tofu, cubed", "Broccoli florets", "Carrots, sliced", "Bell peppers, sliced", "Soy sauce", "Ginger, minced", "Garlic, minced", "Sesame oil", "Cooked rice for serving"],
      "instructions": ["In a wok, heat sesame oil over medium-high heat.", "Add minced ginger and garlic, sauté until fragrant.", "Add cubed tofu and stir-fry until golden brown.", "Add broccoli, carrots, and bell peppers. Cook until vegetables are tender-crisp.", "Pour soy sauce over the stir-fry and toss to combine.", "Serve over cooked rice."],
      "prepTimeMinutes": 15,
      "cookTimeMinutes": 20,
      "servings": 3,
      "difficulty": "Medium",
      "cuisine": "Asian",
      "caloriesPerServing": 250,
      "image": "https://cdn.dummyjson.com/recipe-images/2.webp",
      "mealType": ["Lunch"]
    },
    {
      "id": 3,
      "name": "Chocolate Chip Cookies",
      "ingredients": ["All-purpose flour", "Butter, softened", "Brown sugar", "White sugar", "Eggs", "Vanilla extract", "Baking soda", "Salt", "Chocolate chips"],
      "instructions": ["Preheat the oven to 350°F (175°C).", "In a bowl, cream together softened butter, brown sugar, and white sugar.", "Beat in eggs one at a time, then stir in vanilla extract.", "Combine flour, baking soda, and salt. Gradually add to the wet ingredients.", "Fold in chocolate chips.", "Drop rounded tablespoons of dough onto ungreased baking sheets.", "Bake for 10-12 minutes or until edges are golden brown.", "Allow cookies to cool on the baking sheet for a few minutes before transferring to a wire rack."],
      "prepTimeMinutes": 15,
      "cookTimeMinutes": 10,
      "servings": 24,
      "difficulty": "Easy",
      "cuisine": "American",
      "caloriesPerServing": 150,
      "image": "https://cdn.dummyjson.com/recipe-images/3.webp",
      "mealType": ["Snack", "Dessert"]
    },
    {
      "id": 4,
      "name": "Pasta Primavera",
      "ingredients": ["Pasta", "Vegetables", "Olive oil", "Parmesan"],
      "instructions": ["Boil pasta.", "Sauté veggies.", "Mix and serve."],
      "prepTimeMinutes": 10,
      "cookTimeMinutes": 15,
      "servings": 2,
      "difficulty": "Easy",
      "cuisine": "Italian",
      "caloriesPerServing": 400,
      "image": "https://cdn.dummyjson.com/recipe-images/4.webp",
      "mealType": ["Lunch", "Dinner"]
    },
    {
      "id": 5,
      "name": "Nasi Lemak",
      "ingredients": ["Rice", "Coconut milk", "Anchovies", "Peanuts", "Egg"],
      "instructions": ["Rice with coconut milk.", "Fried anchovies and peanuts.", "Boil egg.", "Sambal."],
      "prepTimeMinutes": 20,
      "cookTimeMinutes": 30,
      "servings": 1,
      "difficulty": "Medium",
      "cuisine": "Malaysian",
      "caloriesPerServing": 600,
      "image": "https://cdn.dummyjson.com/recipe-images/5.webp",
      "mealType": ["Breakfast"]
    }
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(monday.year, monday.month, monday.day);
    _initializeMealPlan();
  }

  void _initializeMealPlan() {
    _mealPlan.clear();
    final mondayStr = DateFormat('yyyy-MM-dd').format(_currentWeekStart);
    _mealPlan[mondayStr] = <Meal>[
      Meal(
        title: 'Nasi Lemak',
        mealType: 'Breakfast',
        servings: 1,
        calories: 180,
        originalData: _savedRecipes[4],
      ),
      Meal(
        title: 'Leftover Pizza',
        mealType: 'Lunch',
        servings: 2,
        calories: 550,
        originalData: _savedRecipes[0],
      ),
    ];

    final wednesdayStr =
        DateFormat('yyyy-MM-dd').format(_currentWeekStart.add(const Duration(days: 2)));
    _mealPlan[wednesdayStr] = <Meal>[
      Meal(
        title: 'Chicken Rendang',
        mealType: 'Lunch',
        servings: 4,
        calories: 450,
        originalData: _savedRecipes[4],
      ),
    ];
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _initializeMealPlan();
    });
  }

  void _deleteMeal(String dateKey, int index) {
    setState(() {
      _mealPlan[dateKey]?.removeAt(index);
      if (_mealPlan[dateKey]?.isEmpty ?? false) {
        _mealPlan.remove(dateKey);
      }
    });
  }

  void _showAddMealSheet(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    String selectedCategory = 'Breakfast';
    int? selectedRecipeIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12.0),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Meal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003D33),
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d').format(date),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        const Text('Meal Category',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          children: ['Breakfast', 'Lunch', 'Dinner', 'High Tea'].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (v) => setModalState(() => selectedCategory = cat),
                              selectedColor: const Color(0xFFE8F5E9),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFF1DB954) : Colors.black87,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF1DB954) : Colors.grey[300]!,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Custom'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1DB954),
                            side: const BorderSide(color: Color(0xFF1DB954)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search my recipes...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('My Saved Recipes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        ...List.generate(_savedRecipes.length, (index) {
                          final recipe = _savedRecipes[index];
                          final isSelected = selectedRecipeIndex == index;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected ? const Color(0xFF1DB954) : Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.restaurant, color: Color(0xFF1DB954)),
                              ),
                              title: Text(recipe['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Radio<int>(
                                value: index,
                                groupValue: selectedRecipeIndex,
                                onChanged: (v) => setModalState(() => selectedRecipeIndex = v),
                                activeColor: const Color(0xFF1DB954),
                              ),
                              onTap: () => setModalState(() => selectedRecipeIndex = index),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: selectedRecipeIndex == null
                          ? null
                          : () {
                              final recipe = _savedRecipes[selectedRecipeIndex!];
                              setState(() {
                                if (!_mealPlan.containsKey(dateKey)) {
                                  _mealPlan[dateKey] = <Meal>[];
                                }
                                _mealPlan[dateKey]!.add(Meal(
                                  title: recipe['name'],
                                  mealType: selectedCategory,
                                  servings: recipe['servings'] ?? 1,
                                  calories: recipe['caloriesPerServing'] ?? 0,
                                  originalData: recipe,
                                ));
                              });
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Selection',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildMealPlanView()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScanPage.show(context),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28.0),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTopTab('Meal Plan', true),
                    _buildTopTab('My Recipes', false, onTap: () => context.push('/my-recipes')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal Plan',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003D33))),
                  Text('Weekly view', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = !isEditing),
                icon: Icon(isEditing ? Icons.check : Icons.edit_outlined, size: 18),
                label: Text(isEditing ? 'Done' : 'Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? const Color(0xFF1DB954) : Colors.white,
                  foregroundColor: isEditing ? Colors.white : Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[200]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(100, 44),
                ),
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1DB954)),
                  SizedBox(width: 8),
                  Text('Tap a meal to edit, or use the icons to modify entries',
                      style: TextStyle(color: Color(0xFF1DB954), fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF003D33) : Colors.grey)),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildToggleOption('Weekly', Icons.calendar_today_outlined, isWeeklyView,
              () => setState(() => isWeeklyView = true)),
          _buildToggleOption('Monthly', Icons.calendar_view_month_outlined, !isWeeklyView,
              () => setState(() => isWeeklyView = false)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow:
                  isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF003D33) : Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF003D33) : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanView() {
    if (!isWeeklyView) {
      return MonthlyPage(
        mealPlan: _mealPlan,
        isEditing: isEditing,
        onDeleteMeal: (dateKey) => setState(() => _mealPlan.remove(dateKey)),
      );
    }

    final weekRange =
        '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(_currentWeekStart.add(const Duration(days: 6)))}';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        _buildWeekNavigator(weekRange),
        const SizedBox(height: 24),
        ...List.generate(7, (index) {
          final date = _currentWeekStart.add(Duration(days: index));
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final meals = _mealPlan[dateKey] ?? <Meal>[];
          return DayContainer(
            date: date,
            meals: meals,
            isEditing: isEditing,
            onAddMeal: () => _showAddMealSheet(date),
            onDeleteMeal: (idx) => _deleteMeal(dateKey, idx),
            onMealTap: (meal) {
              if (meal.originalData != null) {
                context.pushNamed('recipe-view', extra: Map<String, dynamic>.from(meal.originalData!));
              }
            },
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWeekNavigator(String range) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () => _changeWeek(-7), icon: const Icon(Icons.chevron_left, color: Color(0xFF1DB954))),
        Column(
          children: [
            Text(range,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF003D33))),
            const Text('THIS WEEK', style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
          ],
        ),
        IconButton(
            onPressed: () => _changeWeek(7), icon: const Icon(Icons.chevron_right, color: Color(0xFF1DB954))),
      ],
    );
  }
}

class DayContainer extends StatelessWidget {
  final DateTime date;
  final List<Meal> meals;
  final bool isEditing;
  final VoidCallback onAddMeal;
  final Function(int) onDeleteMeal;
  final Function(Meal) onMealTap;

  const DayContainer({
    super.key,
    required this.date,
    required this.meals,
    required this.isEditing,
    required this.onAddMeal,
    required this.onDeleteMeal,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration:
                BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(dayName.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1DB954))),
                Text(dayNum,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1DB954))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: meals.isEmpty
                ? (isEditing
                    ? _buildDottedAddButton()
                    : const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Text('No meal planned', style: TextStyle(color: Colors.grey, fontSize: 16))))
                : Column(
                    children: [
                      ...meals.asMap().entries.map((entry) => MealEntry(
                            meal: entry.value,
                            isEditing: isEditing,
                            onDelete: () => onDeleteMeal(entry.key),
                            onTap: () => onMealTap(entry.value),
                          )),
                      if (isEditing)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4),
                            child: IconButton(
                              onPressed: onAddMeal,
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF1DB954),
                                  minimumSize: const Size(40, 40)),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedAddButton() {
    return CustomPaint(
      painter: _DottedBorderPainter(color: const Color(0xFF1DB954).withValues(alpha: 0.3)),
      child: InkWell(
        onTap: onAddMeal,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Color(0xFF1DB954), size: 20),
              SizedBox(width: 8),
              Text('Plan a meal',
                  style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class MealEntry extends StatelessWidget {
  final Meal meal;
  final bool isEditing;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MealEntry({
    super.key,
    required this.meal,
    required this.isEditing,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4)],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration:
                      BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: Text(meal.mealType.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.orange)),
                ),
                if (isEditing)
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1DB954))),
                      IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(meal.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D33))),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${meal.servings}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${meal.calories}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;

  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(16)));

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double distance = 0.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
