import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/detected_pantry_item.dart';
import '../services/pantry_ai_service.dart';
import 'scan_result_screen.dart';

enum ScanMode { scanItem, scanBarcode }

class PantryScanScreen extends StatefulWidget {
  const PantryScanScreen({super.key});

  @override
  State<PantryScanScreen> createState() => _PantryScanScreenState();
}

class _PantryScanScreenState extends State<PantryScanScreen>
    with WidgetsBindingObserver {
  ScanMode _mode = ScanMode.scanItem;
  bool _isProcessing = false;
  bool _barcodeHandled = false;

  // Camera (Scan Item mode)
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;

  // Barcode (Scan Barcode mode)
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final _imagePicker = ImagePicker();
  final _aiService = PantryAiService();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scannerController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  // ── Camera init ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraError = 'Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _cameraError = 'No camera found on this device');
      return;
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  Future<void> _captureAndDetect() async {
    if (!_cameraReady || _cameraController == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final xFile = await _cameraController!.takePicture();
      await _processImage(File(xFile.path));
    } catch (e) {
      if (mounted) _showError('Capture failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadAndDetect() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isProcessing = true);
    await _processImage(File(picked.path));
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final items = await _aiService.detectItemsFromImage(imageFile);
      if (!mounted) return;
      if (items.isEmpty) {
        _showError('No items detected. Try better lighting or a closer shot.');
        setState(() => _isProcessing = false);
        return;
      }
      _navigateToResult(items);
    } catch (e) {
      if (mounted) {
        _showError('Detection error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  // ── Barcode ───────────────────────────────────────────────────────────────

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_barcodeHandled || _mode != ScanMode.scanBarcode) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
    _barcodeHandled = true;
    _handleBarcode(barcode);
  }

  Future<void> _handleBarcode(String barcode) async {
    setState(() => _isProcessing = true);
    try {
      final item = await _lookupBarcode(barcode);
      if (!mounted) return;

      if (item == null) {
        setState(() {
          _isProcessing = false;
          _barcodeHandled = false;
        });
        _showNotFoundDialog(barcode);
        return;
      }

      _navigateToResult([item]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _barcodeHandled = false;
        });
        _showError('Barcode lookup failed: $e');
      }
    }
  }

  /// Returns null if product not found or data is unreliable
  Future<DetectedPantryItem?> _lookupBarcode(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
    );

    final response = await _aiService.httpClient
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    // Product not in database
    if (data['status'] != 1) return null;

    final p = data['product'] as Map<String, dynamic>? ?? {};

    // Must have a valid product name
    final productName = (p['product_name'] as String? ?? '').trim();
    if (productName.isEmpty) return null;

    // Map Open Food Facts category tags → our categories
    final tags = (p['categories_tags'] as List<dynamic>? ?? [])
        .map((t) => t.toString().toLowerCase())
        .toList();

    String category = 'other';
    if (tags.any((t) =>
    t.contains('beverages') ||
        t.contains('drinks') ||
        t.contains('waters'))) {
      category = 'beverages';
    } else if (tags.any((t) =>
    t.contains('dairy') || t.contains('milk'))) {
      category = 'dairy';
    } else if (tags.any((t) =>
    t.contains('snack') ||
        t.contains('biscuit') ||
        t.contains('chocolate'))) {
      category = 'snacks';
    } else if (tags.any((t) => t.contains('frozen'))) {
      category = 'frozen';
    } else if (tags.any((t) =>
    t.contains('cereal') ||
        t.contains('grain') ||
        t.contains('bread'))) {
      category = 'grains';
    } else if (tags.any((t) =>
    t.contains('sauce') || t.contains('condiment'))) {
      category = 'condiments';
    } else if (tags.any((t) =>
    t.contains('meat') || t.contains('poultry'))) {
      category = 'meat';
    } else if (tags.any((t) =>
    t.contains('seafood') || t.contains('fish'))) {
      category = 'seafood';
    } else if (tags.any((t) =>
    t.contains('spice') || t.contains('herb'))) {
      category = 'spices';
    }

    // Parse quantity + unit from product quantity string e.g. "500 ml", "1 kg"
    double quantity = 1;
    String unit = 'pieces';
    final qtyString =
    (p['quantity'] as String? ?? '').toLowerCase().trim();
    if (qtyString.isNotEmpty) {
      final match = RegExp(r'([\d.]+)\s*(ml|l|g|kg|oz|fl\s*oz)?')
          .firstMatch(qtyString);
      if (match != null) {
        quantity = double.tryParse(match.group(1) ?? '1') ?? 1;
        final rawUnit = (match.group(2) ?? '').trim();
        unit = switch (rawUnit) {
          'ml'    => 'mL',
          'l'     => 'L',
          'g'     => 'g',
          'kg'    => 'kg',
          'oz'    => 'g',
          'fl oz' => 'mL',
          _       => 'pieces',
        };
      }
    }

    // Brand — clean up multiple brands separated by commas
    String? brand = (p['brands'] as String? ?? '').trim();
    if (brand!.isEmpty) brand = null;
    if (brand != null && brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }

    return DetectedPantryItem(
      itemName:            productName,
      brand:               brand,
      category:            category,
      quantity:            quantity,
      unit:                unit,
      usageState:          'full',
      usagePercent:        100,
      storageLocation:     'pantry',
      storageAdvice:       null,
      shelfLifeDays:       null,
      detectionConfidence: 0.95,
    );
  }

  void _showNotFoundDialog(String barcode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 32,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Product not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003D33),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode $barcode was not found in the product database.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              'This may be a regional product not listed in Open Food Facts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 28),

            // Add manually
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  // Pantry page will show AddItemManuallySheet on return
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Add Item Manually',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9A5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Scan different barcode
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Scan Different Barcode',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF003D33),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToResult(List<DetectedPantryItem> items) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultScreen(detectedItems: items),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Mode switch ───────────────────────────────────────────────────────────

  void _switchMode(ScanMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _barcodeHandled = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraLayer(),
          _buildVignette(),
          SafeArea(
            child: Column(
              children: [
                _buildTopControls(),
                const Spacer(),
                if (_mode == ScanMode.scanItem) _buildViewfinder(),
                const SizedBox(height: 12),
                _buildScanLabel(),
                const Spacer(),
                _buildBottomBar(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_mode == ScanMode.scanBarcode) {
      return MobileScanner(
        controller: _scannerController,
        onDetect: _onBarcodeDetected,
      );
    }

    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _cameraError!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildVignette() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.45),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 0.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleOption('Scan Item', ScanMode.scanItem),
                _toggleOption('Scan Barcode', ScanMode.scanBarcode),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, ScanMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D9A5F) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return SizedBox(
      width: 250,
      height: 230,
      child: CustomPaint(painter: _ViewfinderPainter()),
    );
  }

  Widget _buildScanLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _mode == ScanMode.scanItem
            ? 'Point camera at your items'
            : 'Point camera at barcode',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_mode == ScanMode.scanItem)
            GestureDetector(
              onTap: _isProcessing ? null : _uploadAndDetect,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 60),

          if (_mode == ScanMode.scanItem)
            GestureDetector(
              onTap: _isProcessing ? null : _captureAndDetect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cameraReady
                        ? Colors.white.withOpacity(0.85)
                        : Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _cameraReady ? Colors.white : Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2D9A5F).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF2D9A5F).withOpacity(0.6)),
              ),
              child: const Text(
                'Scanning…',
                style: TextStyle(color: Color(0xFF5BC88A), fontSize: 13),
              ),
            ),

          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2D9A5F)),
            SizedBox(height: 16),
            Text(
              'Detecting items…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'This may take a few seconds',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Viewfinder corner painter ─────────────────────────────────────────────────

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8C23A)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const len = 28.0;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(0, len), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => false;
}