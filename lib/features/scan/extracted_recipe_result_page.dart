import 'package:flutter/material.dart';
import '../../services/recipe_extraction_service.dart';
import 'full_recipe_detail_page.dart';
import 'scan_written_recipe_sheet.dart';

class ExtractedRecipeResultPage extends StatefulWidget {
  final ExtractedRecipe recipe;

  const ExtractedRecipeResultPage({super.key, required this.recipe});

  @override
  State<ExtractedRecipeResultPage> createState() =>
      _ExtractedRecipeResultPageState();
}

class _ExtractedRecipeResultPageState extends State<ExtractedRecipeResultPage> {
  final _service = RecipeExtractionService();
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveRecipe() async {
    if (_isSaved) return;
    setState(() => _isSaving = true);
    try {
      await _service.saveToDatabase(widget.recipe);
      setState(() => _isSaved = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Recipe saved successfully! ✓'),
        backgroundColor: Color(0xFF2E7D32),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final hasIngredients = r.ingredients != null && r.ingredients!.isNotEmpty;
    final hasInstructions = r.instructions != null && r.instructions!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Extracted Recipe',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.sourceType == 'url_extract' ? Colors.blue[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: r.sourceType == 'url_extract' ? Colors.blue[200]! : Colors.green[200]!),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  r.sourceType == 'url_extract' ? Icons.link : Icons.camera_alt_outlined,
                  size: 14,
                  color: r.sourceType == 'url_extract' ? Colors.blue[700] : Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  r.sourceType == 'url_extract' ? 'Extracted from URL' : 'Extracted from Image',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: r.sourceType == 'url_extract' ? Colors.blue[700] : Colors.green[700],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Recipe card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title ?? 'Recipe (no title extracted)',
                          style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: r.title != null ? Colors.black87 : Colors.black54,
                            fontStyle: r.title != null ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                        if (r.description != null) ...[
                          const SizedBox(height: 8),
                          Text(r.description!,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
                        ],
                        if (r.prepTimeMinutes != null || r.cookTimeMinutes != null || r.servings != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            if (r.prepTimeMinutes != null)
                              _StatChip(icon: Icons.timer_outlined, label: 'Prep', value: '${r.prepTimeMinutes} min'),
                            if (r.cookTimeMinutes != null) ...[
                              const SizedBox(width: 8),
                              _StatChip(icon: Icons.local_fire_department_outlined, label: 'Cook', value: '${r.cookTimeMinutes} min'),
                            ],
                            if (r.servings != null) ...[
                              const SizedBox(width: 8),
                              _StatChip(icon: Icons.people_outline, label: 'Serves', value: '${r.servings}'),
                            ],
                          ]),
                        ],
                      ],
                    ),
                  ),

                  // Ingredients preview
                  if (hasIngredients) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('Ingredients (${r.ingredients!.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ...r.ingredients!.take(5).map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_formatIngredient(ing),
                            style: const TextStyle(fontSize: 14))),
                      ]),
                    )),
                    if (r.ingredients!.length > 5)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text('+ ${r.ingredients!.length - 5} more ingredients...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 8),
                  ] else
                    const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: _NotExtracted(label: 'Ingredients')),

                  const Divider(height: 24, indent: 20, endIndent: 20),

                  // Instructions preview
                  if (hasInstructions) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('Instructions (${r.instructions!.length} steps)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ...r.instructions!.take(2).toList().asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(child: Text('${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry.value,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
                    if (r.instructions!.length > 2)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text('+ ${r.instructions!.length - 2} more steps...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                  ] else
                    const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: _NotExtracted(label: 'Instructions')),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FullRecipeDetailPage(recipe: widget.recipe),
                )),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('View Full Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSaving || _isSaved) ? null : _saveRecipe,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
                label: Text(_isSaved ? 'Saved to My Recipes ✓' : 'Add to Saved Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? Colors.grey[200] : Colors.orange[50],
                  foregroundColor: _isSaved ? Colors.grey[600] : Colors.orange[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _isSaved ? Colors.grey[300]! : Colors.orange[200]!),
                  ),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ScanWrittenRecipeSheet(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey[300]!),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

class _NotExtracted extends StatelessWidget {
  final String label;
  const _NotExtracted({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100], borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label not found in source',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ]),
    );
  }
}