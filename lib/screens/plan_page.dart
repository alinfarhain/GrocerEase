import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'monthly_page.dart';
import 'scan_page.dart';
import '../models/meal.dart';
import '../services/recipe_service.dart';
import '../services/meal_plan_service.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool isWeeklyView = true;
  bool isEditing = false;
  bool _isLoadingPlan = true;

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  final Map<String, List<Meal>> _mealPlan = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(monday.year, monday.month, monday.day);
    _loadMealPlan();
  }

  // ── DATA LOADING ──────────────────────────────────────────────────────────

  Future<void> _loadMealPlan() async {
    setState(() => _isLoadingPlan = true);
    try {
      final endDate = _currentWeekStart.add(const Duration(days: 6));
      final plan = await MealPlanService.getMealPlansForRange(
        startDate: _currentWeekStart,
        endDate: endDate,
      );
      if (mounted) {
        setState(() {
          _mealPlan.clear();
          _mealPlan.addAll(plan);
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _mealPlan.clear();
    });
    _loadMealPlan();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  // With confirmation dialog — for delete button taps
  Future<void> _deleteMeal(String dateKey, int index) async {
    final meal = _mealPlan[dateKey]?[index];
    if (meal == null) return;

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
    await _deleteMealDirect(dateKey, index);
  }

  // Without dialog — called after swipe confirmDismiss confirms
  Future<void> _deleteMealDirect(String dateKey, int index) async {
    final meal = _mealPlan[dateKey]?[index];
    if (meal == null) return;

    setState(() {
      _mealPlan[dateKey]!.removeAt(index);
      if (_mealPlan[dateKey]!.isEmpty) _mealPlan.remove(dateKey);
    });

    if (meal.id != null) {
      try {
        await MealPlanService.deleteMealPlan(meal.id!);
      } catch (_) {
        if (mounted) {
          setState(() {
            _mealPlan.putIfAbsent(dateKey, () => []).insert(index, meal);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to delete meal. Please try again.')),
          );
        }
      }
    }
  }

  // ── EDIT ──────────────────────────────────────────────────────────────────

  Future<void> _editMeal({
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
          ? (newCustomCategory?.isNotEmpty == true ? newCustomCategory! : 'Custom')
          : newCategory,
      customCategoryName: newCategory == 'Custom' ? newCustomCategory : null,
      servings: meal.servings,
      calories: meal.calories,
      originalData: meal.originalData,
    );

    setState(() {
      final list = _mealPlan[oldDateKey];
      if (list != null && index < list.length) {
        list.removeAt(index);
        if (list.isEmpty) _mealPlan.remove(oldDateKey);
      }
      _mealPlan.putIfAbsent(newDateKey, () => []).add(updatedMeal);
    });

    try {
      await MealPlanService.updateMealPlan(
        id: meal.id!,
        plannedDate: newDate,
        mealCategory: newCategory,
        customCategoryName: newCategory == 'Custom' ? newCustomCategory : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal plan updated!'),
            backgroundColor: Color(0xFF1DB954),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _loadMealPlan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update meal. Please try again.')),
        );
      }
    }
  }

  // ── EDIT MEAL SHEET ───────────────────────────────────────────────────────

  void _showEditMealSheet(Meal meal, String dateKey, int index) {
    DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(dateKey);
    final rawCategory = meal.customCategoryName != null ? 'Custom' : meal.mealType;
    String selectedCategory = rawCategory;
    final customCatController = TextEditingController(
      text: meal.customCategoryName ?? '',
    );
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF1DB954)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Edit Meal Plan',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003D33))),
                                Text(meal.title,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
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

                    // Scrollable content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date selector
                          const Text('Select Date',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF003D33))),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime(2101),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF1DB954),
                                      onPrimary: Colors.white,
                                      onSurface: Color(0xFF003D33),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FFF9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFF1DB954)
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      color: Color(0xFF1DB954), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF003D33),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.edit_outlined,
                                      size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Meal Category
                          const Text('Meal Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF003D33))),
                          const SizedBox(height: 10),
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
                              final isSelected = selectedCategory == cat;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1DB954)
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
                                            color: Color(0xFF1DB954)),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF1DB954)
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
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'e.g. Pre-workout, Supper...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),

                          _buildConfirmButton(
                            isSaving: isSaving,
                            isEnabled: true,
                            label: 'Update Plan',
                            onConfirm: () async {
                              setModalState(() => isSaving = true);
                              final customName = selectedCategory == 'Custom'
                                  ? customCatController.text.trim()
                                  : null;
                              customCatController.dispose();
                              Navigator.pop(context);
                              await _editMeal(
                                meal: meal,
                                oldDateKey: dateKey,
                                index: index,
                                newDate: selectedDate,
                                newCategory: selectedCategory,
                                newCustomCategory: customName,
                              );
                            },
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

  // ── ADD MEAL SHEET ────────────────────────────────────────────────────────

  void _showAddMealSheet(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    List<Map<String, dynamic>> sheetRecipes = [];
    bool isLoadingRecipes = true;
    String selectedCategory = 'Breakfast';
    final TextEditingController customCatController = TextEditingController();
    int? selectedRecipeIndex;
    String searchText = '';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingRecipes && sheetRecipes.isEmpty) {
              RecipeService.getUserRecipes().then((recipes) {
                if (context.mounted) {
                  setModalState(() {
                    sheetRecipes = recipes;
                    isLoadingRecipes = false;
                  });
                }
              }).catchError((_) {
                if (context.mounted) {
                  setModalState(() => isLoadingRecipes = false);
                }
              });
            }

            final visibleRecipes = searchText.isEmpty
                ? sheetRecipes
                : sheetRecipes
                .where((r) => (r['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(searchText.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF1DB954)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Add to Plan',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003D33))),
                                Text(
                                    DateFormat('EEEE, MMMM d').format(date),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              customCatController.dispose();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category selector
                            const Text('Meal Category',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF003D33))),
                            const SizedBox(height: 10),
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
                                final isSelected = selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () => setModalState(
                                          () => selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.grey[100],
                                      borderRadius:
                                      BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1DB954)
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
                                              color: Color(0xFF1DB954)),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(cat,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF1DB954)
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
                              const SizedBox(height: 12),
                              TextField(
                                controller: customCatController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Pre-workout, Supper...',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Search field
                            TextField(
                              onChanged: (v) =>
                                  setModalState(() => searchText = v),
                              decoration: InputDecoration(
                                hintText: 'Search your recipes...',
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1DB954), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Recipe list
                            if (isLoadingRecipes)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF1DB954)),
                                ),
                              )
                            else if (visibleRecipes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No recipes found.',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              ...visibleRecipes.asMap().entries.map((e) {
                                final idx = e.key;
                                final recipe = e.value;
                                final isSelected = selectedRecipeIndex == idx;
                                return GestureDetector(
                                  onTap: () => setModalState(
                                          () => selectedRecipeIndex = idx),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1DB954)
                                            : Colors.grey[200]!,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe['name'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? const Color(0xFF1DB954)
                                                      : const Color(
                                                      0xFF003D33),
                                                ),
                                              ),
                                              if ((recipe['caloriesPerServing'] ??
                                                  0) >
                                                  0) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${recipe['caloriesPerServing']} kcal · ${recipe['servings']} servings',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle,
                                              color: Color(0xFF1DB954)),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),

                            _buildConfirmButton(
                              isSaving: isSaving,
                              isEnabled: selectedRecipeIndex != null,
                              label: 'Add to Plan',
                              onConfirm: () async {
                                final recipe =
                                visibleRecipes[selectedRecipeIndex!];
                                setModalState(() => isSaving = true);
                                final customName =
                                selectedCategory == 'Custom'
                                    ? customCatController.text.trim()
                                    : null;
                                try {
                                  final newMeal =
                                  await MealPlanService.addMealPlan(
                                    plannedDate: date,
                                    mealCategory: selectedCategory,
                                    customCategoryName: customName,
                                    recipe: recipe,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _mealPlan
                                          .putIfAbsent(dateKey, () => [])
                                          .add(newMeal);
                                    });
                                  }
                                  customCatController.dispose();
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                        Text('Failed to save meal: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
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

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _buildConfirmButton({
    required bool isSaving,
    required bool isEnabled,
    required String label,
    required VoidCallback onConfirm,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isEnabled && !isSaving) ? onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner,
            color: Colors.white, size: 28.0),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33))),
          const SizedBox(height: 4),
          const Text('Manage meals and recipes',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),

          // Meal Plan | My Recipes tabs
          Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTopTab('Meal Plan', true),
                _buildTopTab('My Recipes', false,
                    onTap: () => context.push('/my-recipes')),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal Plan',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33))),
                  Text('Weekly view',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = !isEditing),
                icon: Icon(
                  isEditing ? Icons.check : Icons.edit_outlined,
                  size: 16,
                ),
                label: Text(isEditing ? 'Done' : 'Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing
                      ? const Color(0xFF1DB954)
                      : const Color(0xFFE8F5E9),
                  foregroundColor: isEditing
                      ? Colors.white
                      : const Color(0xFF003D33),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weekly | Monthly toggle
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildViewTab('Weekly', Icons.calendar_today_outlined,
                    isWeeklyView, () => setState(() => isWeeklyView = true)),
                _buildViewTab('Monthly', Icons.grid_view_outlined,
                    !isWeeklyView, () => setState(() => isWeeklyView = false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, bool isSelected, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF003D33) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewTab(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF003D33)
                      : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                    color: isSelected
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  )),
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
        onDeleteMeal: (dateKey) =>
            setState(() => _mealPlan.remove(dateKey)),
      );
    }

    final weekRange =
        '${DateFormat('MMM d').format(_currentWeekStart)} - '
        '${DateFormat('MMM d').format(_currentWeekStart.add(const Duration(days: 6)))}';

    return RefreshIndicator(
      onRefresh: _loadMealPlan,
      color: const Color(0xFF1DB954),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          _buildWeekNavigator(weekRange),
          const SizedBox(height: 24),
          if (_isLoadingPlan)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1DB954), strokeWidth: 2),
              ),
            )
          else
            ...List.generate(7, (i) {
              final date = _currentWeekStart.add(Duration(days: i));
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final meals = _mealPlan[dateKey] ?? <Meal>[];
              return DayContainer(
                date: date,
                meals: meals,
                isEditing: isEditing,
                onAddMeal: () => _showAddMealSheet(date),
                onDeleteMeal: (idx) => _deleteMeal(dateKey, idx),
                onDeleteMealDirect: (idx) => _deleteMealDirect(dateKey, idx),
                onEditMeal: (meal, idx) =>
                    _showEditMealSheet(meal, dateKey, idx),
                onMealTap: (meal) {
                  if (meal.originalData != null) {
                    context.pushNamed(
                      'recipe-view',
                      extra: Map<String, dynamic>.from(meal.originalData!),
                    );
                  }
                },
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(String range) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, () => _changeWeek(-7)),
          Column(
            children: [
              Text(range,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33))),
              Text(
                _isCurrentWeek() ? 'THIS WEEK' : '',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          _navButton(Icons.chevron_right, () => _changeWeek(7)),
        ],
      ),
    );
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final thisMonday = DateTime(monday.year, monday.month, monday.day);
    return _currentWeekStart == thisMonday;
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF003D33)),
      style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
          minimumSize: const Size(40, 40)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DayContainer
// ─────────────────────────────────────────────────────────────────────────────

class DayContainer extends StatelessWidget {
  final DateTime date;
  final List<Meal> meals;
  final bool isEditing;
  final VoidCallback onAddMeal;
  final void Function(int index) onDeleteMeal;
  final void Function(int index) onDeleteMealDirect;
  final void Function(Meal meal, int index) onEditMeal;
  final void Function(Meal meal) onMealTap;

  const DayContainer({
    super.key,
    required this.date,
    required this.meals,
    required this.isEditing,
    required this.onAddMeal,
    required this.onDeleteMeal,
    required this.onDeleteMealDirect,
    required this.onEditMeal,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? const Color(0xFF1DB954).withOpacity(0.4)
              : Colors.grey[200]!,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date block
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF1DB954)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                      isToday ? Colors.white : const Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                      isToday ? Colors.white : const Color(0xFF003D33),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Meals column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meals.isEmpty)
                    _buildDottedAddButton(context)
                  else ...[
                    ...meals.asMap().entries.map((e) {
                      final idx = e.key;
                      final meal = e.value;
                      return Dismissible(
                        key: ValueKey(
                            meal.id ?? '${date.toIso8601String()}-$idx'),
                        direction: isEditing
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
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
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style:
                                      TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ??
                              false;
                        },
                        onDismissed: (_) => onDeleteMealDirect(idx),
                        child: MealEntry(
                          meal: meal,
                          isEditing: isEditing,
                          onDelete: () => onDeleteMeal(idx),
                          onEdit: () => onEditMeal(meal, idx),
                          onTap: () => onMealTap(meal),
                          isFirst: idx == 0,
                          isLast: idx == meals.length - 1,
                        ),
                      );
                    }),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: onAddMeal,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 16, color: Color(0xFF1DB954)),
                                SizedBox(width: 4),
                                Text('Add another meal',
                                    style: TextStyle(
                                        color: Color(0xFF1DB954),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedAddButton(BuildContext context) {
    return GestureDetector(
      onTap: isEditing ? onAddMeal : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing
                ? const Color(0xFF1DB954).withOpacity(0.4)
                : Colors.grey[200]!,
            style: BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add,
                size: 18,
                color: isEditing
                    ? const Color(0xFF1DB954)
                    : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              'Plan a meal',
              style: TextStyle(
                color:
                isEditing ? const Color(0xFF1DB954) : Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MealEntry
// ─────────────────────────────────────────────────────────────────────────────

class MealEntry extends StatelessWidget {
  final Meal meal;
  final bool isEditing;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const MealEntry({
    super.key,
    required this.meal,
    required this.isEditing,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditing ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _categoryColour(meal.mealType).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meal.categoryLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _categoryColour(meal.mealType),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _categoryColour(meal.mealType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          meal.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003D33),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (meal.calories > 0 || meal.servings > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories > 0 ? '${meal.calories} kcal' : ''}'
                          '${meal.calories > 0 && meal.servings > 0 ? ' · ' : ''}'
                          '${meal.servings > 0 ? '${meal.servings} servings' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            if (isEditing) ...[
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined,
                      size: 16, color: Colors.blue.shade400),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline,
                      size: 16, color: Colors.red.shade400),
                ),
              ),
            ] else ...[
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Color _categoryColour(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFFF9800);
      case 'lunch':
        return const Color(0xFF2196F3);
      case 'dinner':
        return const Color(0xFF9C27B0);
      case 'high tea':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF607D8B);
    }
  }
}