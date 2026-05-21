import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
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

  // Keyed by 'yyyy-MM-dd' — loaded from Supabase
  final Map<String, List<Meal>> _mealPlan = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(monday.year, monday.month, monday.day);
    _loadMealPlan();
  }

  // ── DATA LOADING ─────────────────────────────────────────────────────────

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

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> _deleteMeal(String dateKey, int index) async {
    final meal = _mealPlan[dateKey]?[index];
    if (meal == null) return;

    // Optimistic UI remove
    setState(() {
      _mealPlan[dateKey]!.removeAt(index);
      if (_mealPlan[dateKey]!.isEmpty) _mealPlan.remove(dateKey);
    });

    // Persist to Supabase (if the meal has an id)
    if (meal.id != null) {
      try {
        await MealPlanService.deleteMealPlan(meal.id!);
      } catch (_) {
        // Re-insert on failure
        if (mounted) {
          setState(() {
            _mealPlan.putIfAbsent(dateKey, () => []).insert(index, meal);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete meal. Please try again.')),
          );
        }
      }
    }
  }

  // ── ADD MEAL SHEET ────────────────────────────────────────────────────────

  void _showAddMealSheet(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // Always fetch fresh recipes when the sheet opens
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
            // Kick off recipe load the first time the builder runs
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
                : sheetRecipes.where((r) =>
                (r['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(searchText.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ── Handle ────────────────────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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

                  // ── Body ──────────────────────────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 24),

                        // ── Meal Category ──────────────────────────────────
                        const Text(
                          'Meal Category',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
                            final isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setModalState(
                                      () => selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
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
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF1DB954)
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // ── Custom category text field ─────────────────────
                        if (selectedCategory == 'Custom') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: customCatController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'e.g. Brunch, Supper, Midnight Snack…',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF1DB954)),
                              filled: true,
                              fillColor: const Color(0xFFF7FFF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1DB954)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1DB954), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // ── Search ────────────────────────────────────────
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            onChanged: (v) =>
                                setModalState(() => searchText = v),
                            decoration: InputDecoration(
                              hintText: 'Search my recipes…',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── My Saved Recipes label ────────────────────────
                        Row(
                          children: [
                            const Text(
                              'My Saved Recipes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF003D33),
                              ),
                            ),
                            const Spacer(),
                            if (!isLoadingRecipes)
                              Text(
                                '${visibleRecipes.length} recipe${visibleRecipes.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Recipe list ───────────────────────────────────
                        if (isLoadingRecipes)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1DB954),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (visibleRecipes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.restaurant_menu,
                                      size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    searchText.isEmpty
                                        ? 'No saved recipes yet.\nGo to My Recipes to add some!'
                                        : 'No recipes match "$searchText"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...visibleRecipes.asMap().entries.map((entry) {
                            final index  = entry.key;
                            final recipe = entry.value;
                            final isSelected = selectedRecipeIndex == index;

                            return GestureDetector(
                              onTap: () => setModalState(
                                      () => selectedRecipeIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0FFF4)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1DB954)
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: const Color(0xFF1DB954)
                                          .withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                      : [
                                    BoxShadow(
                                      color:
                                      Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Recipe icon / image
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: recipe['image'] != null &&
                                          (recipe['image'] as String)
                                              .isNotEmpty
                                          ? Image.network(
                                        recipe['image'] as String,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                          Icons.restaurant,
                                          color: Color(0xFF1DB954),
                                          size: 24,
                                        ),
                                      )
                                          : const Icon(
                                        Icons.restaurant,
                                        color: Color(0xFF1DB954),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Recipe info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe['name'] ?? 'Recipe',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF003D33),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[400]),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${recipe['cookTimeMinutes'] ?? 0}m',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500]),
                                              ),
                                              const SizedBox(width: 10),
                                              Icon(Icons.bar_chart,
                                                  size: 12,
                                                  color: Colors.grey[400]),
                                              const SizedBox(width: 3),
                                              Text(
                                                recipe['difficulty'] ?? 'Easy',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Radio
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedRecipeIndex,
                                      onChanged: (v) => setModalState(
                                              () => selectedRecipeIndex = v),
                                      activeColor: const Color(0xFF1DB954),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // ── Confirm button ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        )
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                        24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                    child: _buildConfirmButton(
                      isSaving       : isSaving,
                      isEnabled      : selectedRecipeIndex != null &&
                          (selectedCategory != 'Custom' ||
                              customCatController.text.trim().isNotEmpty),
                      onConfirm      : () async {
                        if (selectedRecipeIndex == null) return;
                        if (selectedCategory == 'Custom' &&
                            customCatController.text.trim().isEmpty) return;

                        setModalState(() => isSaving = true);

                        final recipe = visibleRecipes[selectedRecipeIndex!];
                        final customName = selectedCategory == 'Custom'
                            ? customCatController.text.trim()
                            : null;

                        try {
                          final newMeal = await MealPlanService.addMealPlan(
                            plannedDate        : date,
                            mealCategory       : selectedCategory,
                            customCategoryName : customName,
                            recipe             : recipe,
                          );

                          if (mounted) {
                            setState(() {
                              _mealPlan.putIfAbsent(dateKey, () => []).add(newMeal);
                            });
                          }

                          customCatController.dispose();
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save meal: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
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

  Widget _buildConfirmButton({
    required bool isSaving,
    required bool isEnabled,
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
              color: Colors.white, strokeWidth: 2.5),
        )
            : const Text(
          'Confirm Selection',
          style:
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

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
          const Text(
            'Plan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
          const Text(
            'Manage meals and recipes',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
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
                _buildTopTab(
                  'My Recipes',
                  false,
                  onTap: () => context.push('/my-recipes'),
                ),
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
                  Text(
                    'Meal Plan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  Text(
                    'Weekly view',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = !isEditing),
                icon: Icon(
                  isEditing ? Icons.check : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(isEditing ? 'Done' : 'Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing
                      ? const Color(0xFF1DB954)
                      : Colors.white,
                  foregroundColor: isEditing
                      ? Colors.white
                      : const Color(0xFF003D33),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Week / Month toggle
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _buildViewTab(
                  icon: Icons.calendar_today_outlined,
                  label: 'Weekly',
                  isSelected: isWeeklyView,
                  onTap: () => setState(() => isWeeklyView = true),
                ),
                _buildViewTab(
                  icon: Icons.grid_view_outlined,
                  label: 'Monthly',
                  isSelected: !isWeeklyView,
                  onTap: () => setState(() => isWeeklyView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, bool isSelected,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
              isSelected ? const Color(0xFF003D33) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8F5E9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF003D33)
                      : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected
                      ? const Color(0xFF003D33)
                      : Colors.grey,
                ),
              ),
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
                  color: Color(0xFF1DB954),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            ...List.generate(7, (index) {
              final date =
              _currentWeekStart.add(Duration(days: index));
              final dateKey =
              DateFormat('yyyy-MM-dd').format(date);
              final meals = _mealPlan[dateKey] ?? <Meal>[];
              return DayContainer(
                date: date,
                meals: meals,
                isEditing: isEditing,
                onAddMeal: () => _showAddMealSheet(date),
                onDeleteMeal: (idx) => _deleteMeal(dateKey, idx),
                onMealTap: (meal) {
                  if (meal.originalData != null) {
                    context.pushNamed(
                      'recipe-view',
                      extra: Map<String, dynamic>.from(
                          meal.originalData!),
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
          _navButton(Icons.chevron_left,
                  () => _changeWeek(-7)),
          Column(
            children: [
              Text(
                range,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33),
                ),
              ),
              Text(
                _isCurrentWeek() ? 'THIS WEEK' : '',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          _navButton(Icons.chevron_right,
                  () => _changeWeek(7)),
        ],
      ),
    );
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final monday =
    now.subtract(Duration(days: now.weekday - 1));
    final thisMonday =
    DateTime(monday.year, monday.month, monday.day);
    return _currentWeekStart == thisMonday;
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF003D33)),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey[100],
        minimumSize: const Size(40, 40),
      ),
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
  final void Function(Meal meal) onMealTap;

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
            // Date badge
            Column(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF1DB954)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFF003D33),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFF003D33),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Meals column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meals.isEmpty)
                    _buildDottedAddButton()
                  else ...[
                    ...meals.asMap().entries.map((e) => MealEntry(
                      meal: e.value,
                      isEditing: isEditing,
                      onDelete: () => onDeleteMeal(e.key),
                      onTap: () => onMealTap(e.value),
                      isFirst: e.key == 0,
                      isLast: e.key == meals.length - 1,
                    )),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
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
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: Color(0xFF1DB954),
                                    size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Add another meal',
                                  style: TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
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

  Widget _buildDottedAddButton() {
    return CustomPaint(
      painter: _DottedBorderPainter(
          color: const Color(0xFF1DB954).withOpacity(0.3)),
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
              Text(
                'Plan a meal',
                style: TextStyle(
                  color: Color(0xFF1DB954),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const MealEntry({
    super.key,
    required this.meal,
    required this.isEditing,
    required this.onDelete,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FFF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0F5E0)),
        ),
        child: Row(
          children: [
            // Category colour dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _categoryColour(meal.mealType),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _categoryColour(meal.mealType)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meal.categoryLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _categoryColour(meal.mealType),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF003D33),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.calories} kcal · ${meal.servings} serving${meal.servings == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (isEditing)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              )
            else
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Color _categoryColour(String category) {
    switch (category) {
      case 'Breakfast':
        return const Color(0xFFFF9800);
      case 'Lunch':
        return const Color(0xFF2196F3);
      case 'Dinner':
        return const Color(0xFF9C27B0);
      case 'High Tea':
        return const Color(0xFFE91E63);
      default: // Custom
        return const Color(0xFF00897B);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dotted border painter
// ─────────────────────────────────────────────────────────────────────────────

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final radius = Radius.circular(16);
    final rRect = RRect.fromRectAndRadius(
        Offset.zero & size, radius);
    final path = Path()..addRRect(rRect);
    final metric = path.computeMetrics().first;
    double distance = 0;

    while (distance < metric.length) {
      final end =
      (distance + dashWidth).clamp(0.0, metric.length);
      canvas.drawPath(
          metric.extractPath(distance, end), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter old) =>
      old.color != color;
}