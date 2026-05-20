import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';
import '../services/recipe_service.dart'; // ✅ NEW

class MyRecipes extends StatefulWidget {
  const MyRecipes({super.key, this.initialEditMode = false});

  final bool initialEditMode;

  @override
  State<MyRecipes> createState() {
    return _MyRecipesState();
  }
}

class _MyRecipesState extends State<MyRecipes> {
  bool isSavedRecipesSelected = true;
  String searchQuery = '';
  bool showFilters = false;
  double? minBudget;
  double? maxBudget;
  int? maxDuration;
  int? maxServings;
  int? maxCalories;
  String? selectedDifficulty;

  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  // ✅ CHANGED: No more hardcoded list — populated from Supabase
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true; // ✅ NEW
  String? _errorMessage;  // ✅ NEW

  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialEditMode;
    _loadRecipes(); // ✅ NEW: fetch from Supabase on start
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // ✅ NEW: Loads all recipes for the current user from Supabase
  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recipes = await RecipeService.getUserRecipes();
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recipes. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      minBudget = double.tryParse(_minBudgetController.text);
      maxBudget = double.tryParse(_maxBudgetController.text);
      maxDuration = int.tryParse(_durationController.text);
      maxServings = int.tryParse(_servingsController.text);
      maxCalories = int.tryParse(_caloriesController.text);
      showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _durationController.clear();
      _servingsController.clear();
      _caloriesController.clear();
      minBudget = null;
      maxBudget = null;
      maxDuration = null;
      maxServings = null;
      maxCalories = null;
      selectedDifficulty = null;
    });
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.orange, size: 20.0),
          const SizedBox(width: 8.0),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003D33),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: Colors.grey),
        const SizedBox(width: 4.0),
        Text(value, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
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
                  child: GestureDetector(
                    onTap: () {
                      AppState.of(context, listen: false).setTabIndex(1);
                      context.go('/');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Meal Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
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
                      'My Recipes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D33),
                      ),
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

  Widget _buildFilterField(
      String label,
      TextEditingController controller,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF003D33),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 48.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () =>
          setState(() => selectedDifficulty = isSelected ? null : difficulty),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color:
            isSelected ? Colors.transparent : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF003D33),
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Search saved recipes...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BAB52),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () => setState(() => showFilters = !showFilters),
          child: Container(
            height: 50.0,
            width: 50.0,
            decoration: BoxDecoration(
              color: showFilters
                  ? const Color(0xFF1BAB52)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              Icons.tune,
              color:
              showFilters ? Colors.white : const Color(0xFF003D33),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(20.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  'Min Budget (RM)',
                  _minBudgetController,
                  '0',
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildFilterField(
                  'Max Budget (RM)',
                  _maxBudgetController,
                  '100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  'Max Duration (min)',
                  _durationController,
                  '60',
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildFilterField(
                  'Max Servings',
                  _servingsController,
                  '10',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildFilterField('Max Calories', _caloriesController, '1000'),
          const SizedBox(height: 16.0),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF003D33),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              _buildDifficultyChip('Easy'),
              const SizedBox(width: 12.0),
              _buildDifficultyChip('Medium'),
              const SizedBox(width: 12.0),
              _buildDifficultyChip('Hard'),
            ],
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: Color(0xFF1BAB52),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB52),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0.0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRecipeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      builder: (context) => Padding(
        padding:
        const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Recipe',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Choose how to add your recipe',
                      style: TextStyle(
                          fontSize: 14.0, color: Colors.grey),
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
            _buildAddOption(
              icon: Icons.edit_outlined,
              title: 'Manual Entry',
              subtitle: 'Add recipe details manually',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF1BAB52),
              onTap: () {
                Navigator.pop(context);
                context.push('/recipe-edit', extra: <String, dynamic>{});
              },
            ),
            const SizedBox(height: 16.0),
            _buildAddOption(
              icon: Icons.camera_alt_outlined,
              title: 'Scan Meal or Ingredients',
              subtitle:
              'Get recommended recipe by scanning meal or ingredients',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF1BAB52),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16.0),
            _buildAddOption(
              icon: Icons.description_outlined,
              title: 'Scan Written Recipe',
              subtitle:
              'Extract recipe from text or handwritten notes',
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFFB74D),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required void Function() onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 28.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: const TextStyle(
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
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 54.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1BAB52),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddRecipeSheet,
          borderRadius: BorderRadius.circular(12.0),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8.0),
              Text(
                'Add New Recipe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isEditMode = !_isEditMode),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _isEditMode
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditMode
                  ? Icons.check_circle_outline
                  : Icons.edit_outlined,
              size: 18.0,
              color:
              _isEditMode ? Colors.white : const Color(0xFF1BAB52),
            ),
            const SizedBox(width: 8.0),
            Text(
              _isEditMode ? 'Done' : 'Edit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isEditMode
                    ? Colors.white
                    : const Color(0xFF1BAB52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final isFavourite = recipe['isFavourite'] == true;
    return GestureDetector(
      onTap: () {
        // ✅ Navigate to RecipeView — data is already normalized
        // from Supabase so RecipeView will display it correctly
        context.pushNamed(
          'recipe-view',
          extra: Map<String, dynamic>.from(recipe),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
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
        child: Column(
          children: [
            Row(
              children: [
                if (isFavourite)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 20.0,
                    ),
                  ),
                Expanded(
                  child: Text(
                    recipe['name'] ?? 'Recipe',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                ),
                if (_isEditMode)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _deleteRecipe(recipe);
                      } else if (value == 'favourite') {
                        _toggleFavourite(recipe);
                      } else if (value == 'plan') {
                        _addToPlan(recipe);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Delete Recipe',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'favourite',
                        child: Row(
                          children: [
                            Icon(
                              isFavourite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 20.0,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              isFavourite
                                  ? 'Remove from Favourites'
                                  : 'Add to Favourites',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'plan',
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF1BAB52),
                              size: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text('Add to Plan'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    recipe['difficulty'] ?? 'Easy',
                    style: const TextStyle(
                      color: Color(0xFF1BAB52),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  recipe['mealType'] is List
                      ? (recipe['mealType'] as List).join(', ')
                      : recipe['mealType'] ?? '',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.access_time,
                  '${(recipe['prepTimeMinutes'] ?? 0) + (recipe['cookTimeMinutes'] ?? 0)}m',
                ),
                _buildInfoItem(
                  Icons.attach_money,
                  recipe['price'] ?? 'RM${recipe['budget'] ?? 15}',
                ),
                _buildInfoItem(
                  Icons.people_outline,
                  '${recipe['servings'] ?? 4}',
                ),
                _buildInfoItem(
                  Icons.local_fire_department_outlined,
                  '${recipe['caloriesPerServing'] ?? recipe['calories'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Deletes from Supabase then removes from local list
  void _deleteRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text(
            'Are you sure you want to delete "${recipe['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final id = recipe['id'];
              if (id != null && id is String) {
                try {
                  await RecipeService.deleteRecipe(id);
                  if (mounted) {
                    setState(() {
                      _recipes.removeWhere((r) => r['id'] == id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recipe deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Toggles favourite locally (no Supabase column yet — add is_favourite
  // column to your recipes table to persist this)
  void _toggleFavourite(Map<String, dynamic> recipe) {
    setState(() {
      final index = _recipes
          .indexWhere((r) => r['id'] == recipe['id']);
      if (index != -1) {
        _recipes[index]['isFavourite'] =
        !(_recipes[index]['isFavourite'] ?? false);
      }
    });
  }

  Future<void> _addToPlan(Map<String, dynamic> recipe) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1BAB52),
            onPrimary: Colors.white,
            onSurface: Color(0xFF003D33),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${recipe['name']}" added to plan for '
                '${picked.day}/${picked.month}/${picked.year}',
          ),
          backgroundColor: const Color(0xFF1BAB52),
        ),
      );
    }
  }

  Widget _buildToggle() {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSavedRecipesSelected) {
                  setState(() => isSavedRecipesSelected = true);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSavedRecipesSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  'My Saved Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSavedRecipesSelected
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                // ✅ AWAIT the navigation — when the user comes back from
                // Search Recipes (whether they saved something or not),
                // reload recipes from Supabase immediately.
                await context.pushNamed('search-recipes');
                if (mounted) _loadRecipes();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isSavedRecipesSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Search Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !isSavedRecipesSelected
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);

    // Apply filters to the Supabase-loaded list
    final filteredRecipes = _recipes.where((recipe) {
      if (searchQuery.isNotEmpty &&
          !(recipe['name'] ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase())) {
        return false;
      }
      final price = double.tryParse(
        (recipe['budget'] ?? recipe['price'] ?? '0')
            .toString()
            .replaceAll(RegExp('[^0-9.]'), ''),
      ) ??
          0.0;
      if (minBudget != null && price < minBudget!) return false;
      if (maxBudget != null && price > maxBudget!) return false;
      final duration = (recipe['cookTimeMinutes'] ?? 0) as int;
      if (maxDuration != null && duration > maxDuration!) return false;
      if (maxServings != null && (recipe['servings'] ?? 0) > maxServings!) {
        return false;
      }
      if (maxCalories != null && (recipe['caloriesPerServing'] ?? 0) > maxCalories!) {
        return false;
      }
      if (selectedDifficulty != null &&
          recipe['difficulty'] != selectedDifficulty) return false;
      return true;
    }).toList();

    final favorites =
    filteredRecipes.where((r) => r['isFavourite'] == true).toList();
    final allRecipes =
    filteredRecipes.where((r) => r['isFavourite'] != true).toList();

    return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          // ✅ Pull-to-refresh: drag down to reload recipes from Supabase
          child: RefreshIndicator(
            onRefresh: _loadRecipes,
            color: const Color(0xFF1BAB52),
            child: SingleChildScrollView(
              // physics needed so RefreshIndicator works even when list is short
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Recipes',
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003D33),
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'View Saved Recipes',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            _buildEditToggle(),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        _buildToggle(),
                        const SizedBox(height: 24.0),
                        _buildSearchBar(),
                        const SizedBox(height: 24.0),
                        if (showFilters) _buildFilterForm(),
                        _buildAddButton(),
                        const SizedBox(height: 24.0),

                        // ✅ NEW: Loading state
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1BAB52),
                              ),
                            ),
                          )
                        // ✅ NEW: Error state
                        else if (_errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 40.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadRecipes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFF1BAB52),
                                    ),
                                    child: const Text('Retry',
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                            // Favorites section
                            if (favorites.isNotEmpty) ...[
                              _buildSectionHeader('Favourites',
                                  icon: Icons.star),
                              const SizedBox(height: 16.0),
                              ...favorites.map(
                                      (r) => _buildRecipeCard(r)),
                              const SizedBox(height: 24.0),
                            ],
                            // All recipes section
                            if (allRecipes.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'All Recipes (${allRecipes.length})'),
                              const SizedBox(height: 16.0),
                              ...allRecipes.map(
                                      (r) => _buildRecipeCard(r)),
                              const SizedBox(height: 24.0),
                            ],
                            // Empty state
                            if (filteredRecipes.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 40.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.restaurant_menu_outlined,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No recipes yet.\nTap "Add New Recipe" to get started!',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10.0,
                offset: const Offset(0.0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1BAB52),
            unselectedItemColor: Colors.grey,
            currentIndex: 1,
            onTap: (index) {
              appState.setTabIndex(index);
              context.go('/');
            },
            selectedLabelStyle: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12.0),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                label: 'Plan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                label: 'List',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                label: 'Pantry',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
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