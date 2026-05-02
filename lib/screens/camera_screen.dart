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

  Color _selectedColor = Colors.white;

  String _colorName = "-";
  double _match = 0;

  String _hexCode = "#FFFFFF";
  String _rgbCode = "RGB(255,255,255)";

  Uint8List? _galleryImage;
  img.Image? _decodedImage;

  Offset? _touchPosition;

  final TransformationController _transformationController =
      TransformationController();

  final GlobalKey _imageKey = GlobalKey();

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

  // =========================
  // SELECT SOURCE POPUP
  // =========================

  void _showSourcePopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Source",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.camera_alt,
                      title: "Camera",
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          _galleryImage = null;
                          _decodedImage = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: _sourceButton(
                      icon: Icons.photo,
                      title: "Gallery",
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 15),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45),

            const SizedBox(height: 15),

            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // =========================
  // PICK IMAGE
  // =========================

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _galleryImage = bytes;
      _decodedImage = img.decodeImage(bytes);
      _touchPosition = null;
    });
  }

  // =========================
  // TOUCH DETECTION
  // =========================

  void _pickColorFromTouch(TapDownDetails details) async {
    if (_galleryImage != null) {
      _pickGalleryColor(details);
    } else {
      _pickCameraColor(details);
    }
  }

  // =========================
  // GALLERY COLOR PICK
  // =========================

  void _pickGalleryColor(TapDownDetails details) {
    if (_decodedImage == null) return;

    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;

    final localPosition = box.globalToLocal(details.globalPosition);

    setState(() {
      _touchPosition = localPosition;
    });

    final size = box.size;

    double scaleX = _decodedImage!.width / size.width;
    double scaleY = _decodedImage!.height / size.height;

    int x = (localPosition.dx * scaleX).toInt();
    int y = (localPosition.dy * scaleY).toInt();

    x = x.clamp(0, _decodedImage!.width - 1);
    y = y.clamp(0, _decodedImage!.height - 1);

    final pixel = _decodedImage!.getPixelSafe(x, y);

    _updateColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
  }

  // =========================
  // CAMERA COLOR PICK
  // =========================

  Future<void> _pickCameraColor(TapDownDetails details) async {
    try {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;

      final localPosition = box.globalToLocal(details.globalPosition);

      setState(() {
        _touchPosition = localPosition;
      });

      final file = await _controller.takePicture();

      final bytes = await file.readAsBytes();

      final image = img.decodeImage(bytes);

      if (image == null) return;

      final size = box.size;

      double scaleX = image.width / size.width;
      double scaleY = image.height / size.height;

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

  // =========================
  // UPDATE COLOR
  // =========================

  void _updateColor(int r, int g, int b) {
    final color = Color.fromARGB(255, r, g, b);

    final match = ColorUtils.getClosest(color);

    final hex =
        "#${r.toRadixString(16).padLeft(2, '0')}"
                "${g.toRadixString(16).padLeft(2, '0')}"
                "${b.toRadixString(16).padLeft(2, '0')}"
            .toUpperCase();

    final rgb = "RGB($r, $g, $b)";

    setState(() {
      _selectedColor = color;

      _colorName = match.name;
      _match = match.match;

      _hexCode = hex;
      _rgbCode = rgb;
    });
  }

  // =========================
  // FLASH
  // =========================

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

  // =========================
  // SAVE
  // =========================

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

  // =========================
  // SAVED COLORS
  // =========================

  void _openSavedColors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedColorsScreen(savedColors: savedColors),
      ),
    );
  }

  // =========================
  // UI
  // =========================

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
                // =========================
                // TOP BAR
                // =========================
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Color Picker",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          _topButton(icon: Icons.photo, onTap: _pickImage),

                          const SizedBox(width: 10),

                          _topButton(
                            icon: _flash ? Icons.flash_on : Icons.flash_off,
                            onTap: _toggleFlash,
                          ),

                          const SizedBox(width: 10),

                          _topButton(
                            icon: Icons.palette,
                            onTap: _openSavedColors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =========================
                // CAMERA / IMAGE VIEW
                // =========================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: GestureDetector(
                        onTapDown: _pickColorFromTouch,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                minScale: 1,
                                maxScale: 5,
                                child: _galleryImage != null
                                    ? Image.memory(
                                        _galleryImage!,
                                        key: _imageKey,
                                        fit: BoxFit.contain,
                                      )
                                    : CameraPreview(
                                        _controller,
                                        key: _imageKey,
                                      ),
                              ),
                            ),

                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(.05),
                              ),
                            ),

                            // =========================
                            // TOUCH POINTER
                            // =========================
                            if (_touchPosition == null)
                              const Center(
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 70,
                                ),
                              ),

                            if (_touchPosition != null)
                              Positioned(
                                left: _touchPosition!.dx - 18,
                                top: _touchPosition!.dy - 18,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // =========================
                            // COLOR PREVIEW
                            // =========================
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // INFO PANEL
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.75),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black12),
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

                            Text("Match ${_match.toStringAsFixed(1)}%"),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(child: _infoCard("HEX", _hexCode)),

                                const SizedBox(width: 12),

                                Expanded(child: _infoCard("RGB", _rgbCode)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: _saveColor,
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  "Save Color",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
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

  // =========================
  // TOP BUTTON
  // =========================

  Widget _topButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
          ],
        ),
        child: Icon(icon),
      ),
    );
  }

  // =========================
  // INFO CARD
  // =========================

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
