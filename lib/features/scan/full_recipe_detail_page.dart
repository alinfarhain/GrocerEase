import 'package:flutter/material.dart';
import '../../services/recipe_extraction_service.dart';

class FullRecipeDetailPage extends StatelessWidget {
  final ExtractedRecipe recipe;
  const FullRecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                ),
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.menu_book, color: Colors.white54, size: 48),
                    const SizedBox(height: 8),
                    if (recipe.title != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(recipe.title!,
                            style: const TextStyle(color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center, maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                )),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.description != null) ...[
                    Text(recipe.description!,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5)),
                    const SizedBox(height: 20),
                  ],
                  if (recipe.prepTimeMinutes != null || recipe.cookTimeMinutes != null || recipe.servings != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (recipe.prepTimeMinutes != null)
                            _StatBox(icon: Icons.timer_outlined, label: 'Prep Time',
                                value: '${recipe.prepTimeMinutes} min'),
                          if (recipe.cookTimeMinutes != null)
                            _StatBox(icon: Icons.local_fire_department_outlined,
                                label: 'Cook Time', value: '${recipe.cookTimeMinutes} min'),
                          if (recipe.servings != null)
                            _StatBox(icon: Icons.people_outline, label: 'Servings',
                                value: '${recipe.servings}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) ...[
                    const Text('Ingredients',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...recipe.ingredients!.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: e.key.isEven ? Colors.grey[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(children: [
                        Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF2E7D32),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_formatIngredient(e.value),
                            style: const TextStyle(fontSize: 14))),
                      ]),
                    )),
                    const SizedBox(height: 24),
                  ],
                  if (recipe.instructions != null && recipe.instructions!.isNotEmpty) ...[
                    const Text('Instructions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...recipe.instructions!.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4, offset: const Offset(0, 1),
                        )],
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 13))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value,
                            style: const TextStyle(fontSize: 14, height: 1.5))),
                      ]),
                    )),
                  ],
                  if (recipe.sourceUrl != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50], borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(recipe.sourceUrl!,
                            style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIngredient(Map<String, dynamic> ing) {
    final parts = <String>[];
    if (ing['quantity'] != null) parts.add(ing['quantity'].toString());
    if (ing['unit'] != null) parts.add(ing['unit'].toString());
    if (ing['name'] != null) parts.add(ing['name'].toString());
    return parts.join(' ');
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF2E7D32), size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    ]);
  }
}