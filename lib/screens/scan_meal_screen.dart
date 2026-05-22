import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_analysis_service.dart';

class ScanMealScreen extends StatefulWidget {
  const ScanMealScreen({super.key});

  @override
  State<ScanMealScreen> createState() => _ScanMealScreenState();
}

class _ScanMealScreenState extends State<ScanMealScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  String _mode = 'meal'; // 'meal' or 'ingredients'
  bool _isLoading = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── CAPTURE FROM CAMERA ──────────────────────────────
  Future<void> _handleCapture() async {
    if (_cameraController == null || !_cameraReady) return;
    setState(() => _isLoading = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _analyze(base64Image);
    } catch (e) {
      _showError('Failed to capture photo');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UPLOAD FROM GALLERY ──────────────────────────────
  Future<void> _handleUpload() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _analyze(base64Image);
    } catch (e) {
      _showError('Failed to load image');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── SEND TO AI ───────────────────────────────────────
  Future<void> _analyze(String base64Image) async {
    try {
      final result = await AIAnalysisService.analyzeImage(
        base64Image: base64Image,
        mode: _mode,
      );
      if (mounted) {
        context.push('/scan-results', extra: result);
      }
    } catch (e) {
      _showError('Analysis failed. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── CAMERA PREVIEW ─────────────────────────
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── TOP BAR ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      // Mode toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _modeButton('meal', 'Detect Meal'),
                            _modeButton('ingredients', 'Detect Ingredients'),
                          ],
                        ),
                      ),

                      const SizedBox(width: 36), // balance spacer
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── SCAN FRAME OVERLAY ──────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(painter: _CornerPainter()),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _mode == 'meal'
                        ? 'Point camera at your meal'
                        : 'Point camera at your ingredients',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM CONTROLS ─────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Upload button
                GestureDetector(
                  onTap: _isLoading ? null : _handleUpload,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white.withOpacity(0.9),
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Capture button
                GestureDetector(
                  onTap: _isLoading ? null : _handleCapture,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                          : Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacer to balance layout
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String value, String label) {
    final isActive = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Draws the 4 corner brackets like image 3
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;

    // Top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}