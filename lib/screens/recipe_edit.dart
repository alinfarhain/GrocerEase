import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../globals/app_state.dart';

class RecipeEdit extends StatefulWidget {
  const RecipeEdit({required this.recipe, super.key});

  final Map<String, dynamic> recipe;

  @override
  State<RecipeEdit> createState() {
    return _RecipeEditState();
  }
}

class _RecipeEditState extends State<RecipeEdit> {
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _budgetController;
  late TextEditingController _caloriesController;
  late int _servings;
  late String _difficulty;
  String? _imagePath;
  bool _isSaving = false; // ✅ NEW

  final List<String> _selectedTools = [];
  final List<TextEditingController> _ingredientNameControllers = [];
  final List<TextEditingController> _ingredientAmountControllers = [];
  final List<TextEditingController> _ingredientUnitControllers = [];
  final List<TextEditingController> _stepControllers = [];

  final List<String> _currentTools = [
    'Pot',
    'Pan',
    'Oven',
    'Blender',
    'Knife',
    'Wok',
    'Grill',
    'Microwave',
  ];

  final List<String> _commonUnits = [
    'g',
    'kg',
    'ml',
    'l',
    'tsp',
    'tbsp',
    'cup',
    'pcs',
    'pack',
    'pinch',
    'slice',
  ];

  void _addIngredientControllers(String name, String amount, String unit) {
    _ingredientNameControllers.add(TextEditingController(text: name));
    _ingredientAmountControllers.add(TextEditingController(text: amount));
    _ingredientUnitControllers.add(TextEditingController(text: unit));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _budgetController.dispose();
    _caloriesController.dispose();
    for (var c in _ingredientNameControllers) {
      c.dispose();
    }
    for (var c in _ingredientAmountControllers) {
      c.dispose();
    }
    for (var c in _ingredientUnitControllers) {
      c.dispose();
    }
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _addIngredientControllers('', '', '');
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientNameControllers[index].dispose();
      _ingredientAmountControllers[index].dispose();
      _ingredientUnitControllers[index].dispose();
      _ingredientNameControllers.removeAt(index);
      _ingredientAmountControllers.removeAt(index);
      _ingredientUnitControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  // ✅ NEW: Save to Supabase
  Future<void> _saveToSupabase() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Build ingredients list
      final ingredients = List.generate(
        _ingredientNameControllers.length,
            (index) => {
          'name': _ingredientNameControllers[index].text,
          'amount': _ingredientAmountControllers[index].text,
          'unit': _ingredientUnitControllers[index].text,
        },
      );

      // Build cooking steps list
      final cookingSteps = _stepControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Map your field names → Supabase column names
      final recipeData = {
        'user_id': userId,
        'recipe_name': _nameController.text.trim(),
        'image_url': _imagePath,
        'cooking_duration': int.tryParse(_durationController.text) ?? 0,
        'estimated_budget': double.tryParse(_budgetController.text) ?? 0.0,
        'servings': _servings,
        'calories_per_serving': int.tryParse(_caloriesController.text) ?? 0,
        'difficulty_level': _difficulty,
        'tools_required': _selectedTools,
        'ingredients': ingredients,
        'cooking_steps': cookingSteps,
      };

      // Check if editing existing or creating new
      final existingId = widget.recipe['id'];

      if (existingId != null) {
        // UPDATE existing recipe
        await supabase
            .from('recipes')
            .update(recipeData)
            .eq('id', existingId);
      } else {
        // INSERT new recipe
        await supabase.from('recipes').insert(recipeData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recipe saved successfully!'),
            backgroundColor: Color(0xFF1BAB52),
          ),
        );
        Navigator.pop(context, recipeData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildImagePickerRow() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE8F5E9)),
        ),
        child: Row(
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: _imagePath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: _imagePath!.startsWith('http')
                    ? Image.network(_imagePath!, fit: BoxFit.cover)
                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
              )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 16.0),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No image selected',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF003D33),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFF1BAB52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF003D33),
        ),
      ),
    );
  }

  Widget _buildLabelWithIcon(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: const Color(0xFF1BAB52)),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {EdgeInsets? contentPadding}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: _buildTextField(controller, '0')),
        const SizedBox(width: 12.0),
        Column(
          children: [
            _dialButton(Icons.keyboard_arrow_up, () {
              int val = int.tryParse(controller.text) ?? 0;
              controller.text = (val + 1).toString();
            }),
            const SizedBox(height: 4.0),
            _dialButton(Icons.keyboard_arrow_down, () {
              int val = int.tryParse(controller.text) ?? 0;
              if (val > 0) {
                controller.text = (val - 1).toString();
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _dialButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, size: 20.0, color: const Color(0xFF003D33)),
      ),
    );
  }

  double? _parseAmount(String text) {
    text = text.trim();
    if (text.isEmpty) return null;

    if (text.contains(' ')) {
      final parts = text.split(' ');
      if (parts.length == 2) {
        final whole = double.tryParse(parts[0]);
        final fraction = _parseFraction(parts[1]);
        if (whole != null && fraction != null) {
          return whole + fraction;
        }
      }
    }

    final fraction = _parseFraction(text);
    if (fraction != null) return fraction;

    return double.tryParse(text);
  }

  double? _parseFraction(String text) {
    final parts = text.split('/');
    if (parts.length == 2) {
      final num = double.tryParse(parts[0]);
      final den = double.tryParse(parts[1]);
      if (num != null && den != null && den != 0) {
        return num / den;
      }
    }
    return null;
  }

  String _formatAmount(double amount, {bool preferFraction = false}) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    final int whole = amount.floor();
    final double fraction = amount - whole;

    String fractionStr = '';
    const epsilon = 0.01;

    if ((fraction - 0.125).abs() < epsilon) {
      fractionStr = '1/8';
    } else if ((fraction - 0.25).abs() < epsilon) {
      fractionStr = '1/4';
    } else if ((fraction - 0.333).abs() < 0.015) {
      fractionStr = '1/3';
    } else if ((fraction - 0.375).abs() < epsilon) {
      fractionStr = '3/8';
    } else if ((fraction - 0.5).abs() < epsilon) {
      fractionStr = '1/2';
    } else if ((fraction - 0.625).abs() < epsilon) {
      fractionStr = '5/8';
    } else if ((fraction - 0.666).abs() < 0.015) {
      fractionStr = '2/3';
    } else if ((fraction - 0.75).abs() < epsilon) {
      fractionStr = '3/4';
    } else if ((fraction - 0.875).abs() < epsilon) {
      fractionStr = '7/8';
    }

    if (fractionStr.isNotEmpty) {
      return whole > 0 ? '$whole $fractionStr' : fractionStr;
    }

    if (preferFraction) {
      final eighths = (fraction * 8).round();
      if (eighths > 0 && eighths < 8) {
        final List<String> eighthStrs = [
          '',
          '1/8',
          '1/4',
          '3/8',
          '1/2',
          '5/8',
          '3/4',
          '7/8'
        ];
        fractionStr = eighthStrs[eighths];
        return whole > 0 ? '$whole $fractionStr' : fractionStr;
      }
    }

    return amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _adjustServings(int newServings) {
    if (newServings < 1 || _servings == 0) return;

    final double ratio = newServings / _servings;

    setState(() {
      for (int i = 0; i < _ingredientAmountControllers.length; i++) {
        final controller = _ingredientAmountControllers[i];
        final unit = _ingredientUnitControllers[i].text.toLowerCase().trim();

        final double? currentAmount = _parseAmount(controller.text);
        if (currentAmount != null) {
          final double newAmount = currentAmount * ratio;
          final bool preferFraction =
          !['g', 'kg', 'ml', 'l', 'mg'].contains(unit);
          controller.text = _formatAmount(
            newAmount,
            preferFraction: preferFraction,
          );
        }
      }
      _servings = newServings;
    });
  }

  Widget _buildCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _counterButton(Icons.remove, () => _adjustServings(_servings - 1)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                height: 56.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  '$_servings',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _counterButton(Icons.add, () => _adjustServings(_servings + 1)),
          ],
        ),
        const SizedBox(height: 8.0),
        const Text(
          'Ingredient quantities will be adjusted automatically',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _counterButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Icon(icon, color: const Color(0xFF003D33)),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    final levels = ['Easy', 'Medium', 'Hard'];
    return Row(
      children: levels.map((lvl) {
        final isSelected = _difficulty == lvl;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: lvl != 'Hard' ? 12.0 : 0.0),
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = lvl),
              child: Container(
                height: 48.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1BAB52) : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Text(
                  lvl,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF003D33),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            margin: const EdgeInsets.only(top: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1BAB52),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: TextField(
              controller: _stepControllers[index],
              maxLines: null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          GestureDetector(
            onTap: () => _removeStep(index),
            child: Container(
              margin: const EdgeInsets.only(top: 12.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFEF5350),
                size: 18.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Color(0xFFFF9800), size: 20.0),
          SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Fields highlighted in yellow are missing or incomplete. Please fill them in.',
              style: TextStyle(
                color: Color(0xFFE65100),
                fontSize: 13.0,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final appState = AppState.of(context);
    return Container(
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
        currentIndex: appState.currentTabIndex,
        onTap: (index) {
          appState.setTabIndex(index);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
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
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe['name'] ?? '');
    _durationController = TextEditingController(
      text: (widget.recipe['cookTimeMinutes'] ?? 0).toString(),
    );
    _budgetController = TextEditingController(text: '15');
    _caloriesController = TextEditingController(
      text: (widget.recipe['caloriesPerServing'] ?? 0).toString(),
    );
    _servings = widget.recipe['servings'] ?? 4;
    _difficulty = widget.recipe['difficulty'] ?? 'Easy';
    _imagePath = widget.recipe['image'];

    _selectedTools.addAll(List<String>.from(
      widget.recipe['tools'] ?? ['Pot', 'Pan'],
    ));

    final instructions = List<String>.from(widget.recipe['instructions'] ?? []);
    if (instructions.isEmpty) {
      instructions.add('');
    }
    for (var step in instructions) {
      _stepControllers.add(TextEditingController(text: step));
    }
    final rawIngredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    if (rawIngredients.isEmpty) {
      _addIngredientControllers('', '', 'g');
    } else {
      for (var ing in rawIngredients) {
        if (ing is Map) {
          _addIngredientControllers(
            ing['name']?.toString() ?? '',
            ing['amount']?.toString() ?? '',
            ing['unit']?.toString() ?? '',
          );
        } else {
          _addIngredientControllers(ing.toString(), '', '');
        }
      }
    }
  }

  void _showAddToolDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Tool'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Air Fryer'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final tool = controller.text.trim();
                  if (!_currentTools.contains(tool)) {
                    _currentTools.add(tool);
                  }
                  _selectedTools.add(tool);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BAB52),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 12.0,
      children: [
        ..._currentTools.map((tool) {
          final isSelected = _selectedTools.contains(tool);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTools.remove(tool);
                } else {
                  _selectedTools.add(tool);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1BAB52) : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFEEEEEE),
                ),
              ),
              child: Text(
                tool,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF003D33),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: _showAddToolDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF1BAB52)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18.0, color: Color(0xFF1BAB52)),
                SizedBox(width: 4.0),
                Text(
                  'Add Tool',
                  style: TextStyle(
                    color: Color(0xFF1BAB52),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(int index) {
    const ingredientPadding =
    EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildTextField(_ingredientNameControllers[index], 'Name',
                contentPadding: ingredientPadding),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 2,
            child: _buildTextField(_ingredientAmountControllers[index], '0',
                contentPadding: ingredientPadding),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                _buildTextField(_ingredientUnitControllers[index], 'unit',
                    contentPadding: ingredientPadding),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  onSelected: (value) {
                    _ingredientUnitControllers[index].text = value;
                  },
                  itemBuilder: (context) => _commonUnits
                      .map(
                        (unit) => PopupMenuItem(value: unit, child: Text(unit)),
                  )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: () => _removeIngredient(index),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFEF5350),
                size: 18.0,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leadingWidth: 0.0,
        title: const Text(
          'Edit Recipe',
          style: TextStyle(
            color: Color(0xFF003D33),
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Color(0xFF003D33)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Recipe Picture'),
            _buildImagePickerRow(),
            const SizedBox(height: 24.0),
            _buildLabel('Recipe Name'),
            _buildTextField(_nameController, 'Enter recipe name'),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(
              Icons.access_time_outlined,
              'Cooking Duration (minutes)',
            ),
            _buildNumberField(_durationController),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(Icons.attach_money, 'Estimated Budget (RM)'),
            _buildTextField(_budgetController, '15'),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(Icons.people_outline, 'Number of Servings'),
            _buildCounter(),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(
              Icons.local_fire_department_outlined,
              'Calories (per serving)',
            ),
            _buildTextField(_caloriesController, '450'),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(
              Icons.restaurant_menu_outlined,
              'Difficulty Level',
            ),
            _buildDifficultySelector(),
            const SizedBox(height: 24.0),
            _buildLabelWithIcon(Icons.handyman_outlined, 'Tools Required'),
            _buildToolsSelector(),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33),
                  ),
                ),
                GestureDetector(
                  onTap: _addIngredient,
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF1BAB52), size: 18.0),
                      Text(
                        ' Add',
                        style: TextStyle(
                          color: Color(0xFF1BAB52),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ...List.generate(
              _ingredientNameControllers.length,
                  (index) => _buildIngredientRow(index),
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cooking Steps',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33),
                  ),
                ),
                GestureDetector(
                  onTap: _addStep,
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF1BAB52), size: 18.0),
                      Text(
                        ' Add',
                        style: TextStyle(
                          color: Color(0xFF1BAB52),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ...List.generate(
              _stepControllers.length,
                  (index) => _buildStepRow(index),
            ),
            const SizedBox(height: 32.0),
            _buildWarningBox(),
            const SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              height: 56.0,
              child: ElevatedButton(
                // ✅ NEW: calls _saveToSupabase, disables while saving
                onPressed: _isSaving ? null : _saveToSupabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BAB52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 0.0,
                ),
                // ✅ NEW: shows spinner while saving
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Recipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}