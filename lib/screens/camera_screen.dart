import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:colorpicker/color_utils.dart';
import 'package:colorpicker/screens/saved_colors_screen.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initialize;

  final ImagePicker _picker = ImagePicker();

  bool _flash = false;

  /// true = gallery
  /// false = camera
  bool _isGalleryMode = false;

  Uint8List? _galleryImage;
  img.Image? _decodedImage;

  Offset? _touchPosition;

  final GlobalKey _imageKey = GlobalKey();

  final TransformationController _transformationController =
      TransformationController();

  // =========================
  // COLOR INFO
  // =========================

  Color _selectedColor = Colors.white;

  String _colorName = "White";
  double _match = 100;

  String _hexCode = "#FFFFFF";
  String _rgbCode = "RGB(255,255,255)";

  List<Map<String, dynamic>> savedColors = [];

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initialize = _controller.initialize().then((_) async {
      await _controller.setFlashMode(FlashMode.off);

      Future.delayed(Duration.zero, () {
        _showSourcePopup();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // =====================================================
  // SOURCE POPUP
  // =====================================================

  void _showSourcePopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xfff5f7fb),
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Choose Source",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.camera_alt_rounded,
                      title: "Camera",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          _isGalleryMode = false;
                          _galleryImage = null;
                          _decodedImage = null;
                          _touchPosition = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: _sourceButton(
                      icon: Icons.photo_library_rounded,
                      title: "Gallery",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PICK IMAGE
  // =====================================================

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _isGalleryMode = true;

      _galleryImage = bytes;
      _decodedImage = img.decodeImage(bytes);

      _touchPosition = null;
    });
  }

  // =====================================================
  // SWITCH TO CAMERA
  // =====================================================

  void _switchToCamera() {
    setState(() {
      _isGalleryMode = false;

      _galleryImage = null;
      _decodedImage = null;

      _touchPosition = null;
    });
  }

  // =====================================================
  // TOUCH DETECTION
  // =====================================================

  void _pickColor(TapDownDetails details) {
    if (_isGalleryMode) {
      _pickGalleryColor(details);
    } else {
      _pickCameraColor(details);
    }
  }

  // =====================================================
  // GALLERY COLOR PICK
  // =====================================================

  void _pickGalleryColor(TapDownDetails details) {
    if (_decodedImage == null) return;

    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;

    final localPosition = box.globalToLocal(details.globalPosition);

    setState(() {
      _touchPosition = localPosition;
    });

    final size = box.size;

    final scaleX = _decodedImage!.width / size.width;
    final scaleY = _decodedImage!.height / size.height;

    int x = (localPosition.dx * scaleX).toInt();
    int y = (localPosition.dy * scaleY).toInt();

    x = x.clamp(0, _decodedImage!.width - 1);
    y = y.clamp(0, _decodedImage!.height - 1);

    final pixel = _decodedImage!.getPixelSafe(x, y);

    _updateColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
  }

  // =====================================================
  // CAMERA COLOR PICK
  // =====================================================

  Future<void> _pickCameraColor(TapDownDetails details) async {
    try {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;

      final localPosition = box.globalToLocal(details.globalPosition);

      setState(() {
        _touchPosition = localPosition;
      });

      final XFile file = await _controller.takePicture();

      final Uint8List bytes = await file.readAsBytes();

      final image = img.decodeImage(bytes);

      if (image == null) return;

      final size = box.size;

      final scaleX = image.width / size.width;
      final scaleY = image.height / size.height;

      int x = (localPosition.dx * scaleX).toInt();
      int y = (localPosition.dy * scaleY).toInt();

      x = x.clamp(0, image.width - 1);
      y = y.clamp(0, image.height - 1);

      final pixel = image.getPixelSafe(x, y);

      _updateColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // =====================================================
  // UPDATE COLOR
  // =====================================================

  void _updateColor(int r, int g, int b) {
    final color = Color.fromARGB(255, r, g, b);

    final match = ColorUtils.getClosest(color);

    final hex =
        "#${r.toRadixString(16).padLeft(2, '0')}"
                "${g.toRadixString(16).padLeft(2, '0')}"
                "${b.toRadixString(16).padLeft(2, '0')}"
            .toUpperCase();

    setState(() {
      _selectedColor = color;

      _colorName = match.name;
      _match = match.match;

      _hexCode = hex;
      _rgbCode = "RGB($r, $g, $b)";
    });
  }

  // =====================================================
  // FLASH
  // =====================================================

  Future<void> _toggleFlash() async {
    try {
      if (_flash) {
        await _controller.setFlashMode(FlashMode.off);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _flash = !_flash;
      });
    } catch (_) {}
  }

  // =====================================================
  // SAVE
  // =====================================================

  void _saveColor() {
    savedColors.add({
      "name": _colorName,
      "match": _match,
      "hex": _hexCode,
      "rgb": _rgbCode,
      "color": _selectedColor,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Color Saved")));
  }

  // =====================================================
  // OPEN SAVED
  // =====================================================

  void _openSavedColors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedColorsScreen(savedColors: savedColors),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      body: FutureBuilder(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Column(
              children: [
                // =====================================================
                // TOP BAR
                // =====================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Color Picker",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "Tap anywhere to detect color",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          _premiumButton(
                            icon: Icons.swap_horiz_rounded,
                            onTap: _showSourcePopup,
                          ),

                          const SizedBox(width: 3),

                          _premiumButton(
                            icon: Icons.flash_on_rounded,
                            onTap: _toggleFlash,
                            active: _flash,
                          ),

                          const SizedBox(width: 3),

                          _premiumButton(
                            icon: Icons.palette_rounded,
                            onTap: _openSavedColors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =====================================================
                // IMAGE / CAMERA VIEW
                // =====================================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTapDown: _pickColor,
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              minScale: 1,
                              maxScale: 8,
                              child: SizedBox.expand(
                                child: _isGalleryMode
                                    ? Image.memory(
                                        _galleryImage!,
                                        key: _imageKey,
                                        fit: BoxFit.cover,
                                      )
                                    : CameraPreview(
                                        _controller,
                                        key: _imageKey,
                                      ),
                              ),
                            ),
                          ),

                          // Overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(.25),
                                      Colors.transparent,
                                      Colors.black.withOpacity(.15),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // POINTER
                          if (_touchPosition != null)
                            Positioned(
                              left: _touchPosition!.dx - 22,
                              top: _touchPosition!.dy - 22,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // LIVE COLOR
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.25),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // MODE BADGE
                          Positioned(
                            top: 24,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isGalleryMode ? "Gallery" : "Camera",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =====================================================
                // INFO PANEL
                // =====================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.82),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _colorName,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Match ${_match.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(child: _infoCard("HEX", _hexCode)),

                                const SizedBox(width: 12),

                                Expanded(child: _infoCard("RGB", _rgbCode)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    title: "Save Color",
                                    icon: Icons.save,
                                    color: _selectedColor,
                                    onTap: _saveColor,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: _actionButton(
                                    title: _isGalleryMode
                                        ? "Camera"
                                        : "Gallery",
                                    icon: _isGalleryMode
                                        ? Icons.camera_alt
                                        : Icons.photo,
                                    color: Colors.black,
                                    textColor: Colors.white,
                                    onTap: _isGalleryMode
                                        ? _switchToCamera
                                        : _pickImage,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // PREMIUM BUTTON
  // =====================================================

  Widget _premiumButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: active ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.black87),
      ),
    );
  }

  // =====================================================
  // ACTION BUTTON
  // =====================================================

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // INFO CARD
  // =====================================================

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
