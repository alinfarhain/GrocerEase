import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/recipe_extraction_service.dart';
import 'extracted_recipe_result_page.dart';

class ScanWrittenRecipeSheet extends StatefulWidget {
  const ScanWrittenRecipeSheet({super.key});

  @override
  State<ScanWrittenRecipeSheet> createState() => _ScanWrittenRecipeSheetState();
}

class _ScanWrittenRecipeSheetState extends State<ScanWrittenRecipeSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _service = RecipeExtractionService();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _error = null;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractFromImage() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final recipe = await _service.extractFromImage(_selectedImage!);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ExtractedRecipeResultPage(recipe: recipe),
      ));
    } catch (e) {
      setState(() => _error = 'Extraction failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _extractFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL.');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _error = 'Please enter a valid URL starting with https://');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final recipe = await _service.extractFromUrl(url);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ExtractedRecipeResultPage(recipe: recipe),
      ));
    } catch (e) {
      setState(() => _error = 'Extraction failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recipe Input',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose Input Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            // Toggle tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() => _error = null),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4, offset: const Offset(0, 2),
                    )],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(height: 44, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Scan Recipe'),
                      ],
                    )),
                    Tab(height: 44, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, size: 16),
                        SizedBox(width: 6),
                        Text('Paste URL'),
                      ],
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  ]),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ScanRecipeTab(
                    selectedImage: _selectedImage,
                    isLoading: _isLoading,
                    onPickImage: _showImageSourceDialog,
                    onExtract: _extractFromImage,
                  ),
                  _PasteUrlTab(
                    controller: _urlController,
                    isLoading: _isLoading,
                    onExtract: _extractFromUrl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Scan Recipe ────────────────────────────────────────────────────
class _ScanRecipeTab extends StatelessWidget {
  final File? selectedImage;
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onExtract;

  const _ScanRecipeTab({
    required this.selectedImage,
    required this.isLoading,
    required this.onPickImage,
    required this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scan Recipe',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isLoading ? null : onPickImage,
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(fit: StackFit.expand, children: [
                  Image.file(selectedImage!, fit: BoxFit.cover),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: isLoading ? null : onPickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ]),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Upload or scan a recipe image',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onPickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Upload Image'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Scan or upload an image of the recipe',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onExtract,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward),
              label: Text(isLoading ? 'Extracting...' : 'Extract Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedImage != null
                    ? const Color(0xFF2E7D32) : Colors.grey[300],
                foregroundColor: selectedImage != null
                    ? Colors.white : Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TipsCard(),
        ],
      ),
    );
  }
}

// ── Tab 2: Paste URL ──────────────────────────────────────────────────────
class _PasteUrlTab extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onExtract;

  const _PasteUrlTab({
    required this.controller,
    required this.isLoading,
    required this.onExtract,
  });

  static const _examples = [
    'https://allrecipes.com/recipe/...',
    'https://foodnetwork.com/recipes/...',
    'https://tasty.co/recipe/...',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recipe Website URL',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !isLoading,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'https://example.com/recipe',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text('Enter the full URL of the recipe website',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 16),
          Text('Quick examples:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._examples.map((url) => GestureDetector(
            onTap: () => controller.text = url.replaceAll('...', ''),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(url,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12,
                      fontFamily: 'monospace')),
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onExtract,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward),
              label: Text(isLoading ? 'Extracting...' : 'Extract Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TipsCard(),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('💡', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ...[
            'For best results, include both ingredients and instructions',
            'URLs from popular recipe sites work best',
            'Make sure the recipe is clearly formatted',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(fontSize: 12)),
              Expanded(child: Text(tip, style: const TextStyle(fontSize: 12))),
            ]),
          )),
        ],
      ),
    );
  }
}