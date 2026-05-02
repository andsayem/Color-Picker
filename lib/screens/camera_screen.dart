import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:colorpicker/color_utils.dart';
import 'package:colorpicker/screens/saved_colors_screen.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initialize;

  bool _flash = false;
  bool _isDetecting = false;

  Color _liveColor = Colors.transparent;

  String _colorName = "-";
  double _match = 0;

  String _hexCode = "#------";
  String _rgbCode = "RGB(0,0,0)";

  List<Map<String, dynamic>> savedColors = [];

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initialize = _controller.initialize().then((_) async {
      // 🔥 Default flash OFF
      await _controller.setFlashMode(FlashMode.off);

      _flash = false;

      _startLiveDetection();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔥 LIVE COLOR DETECTION
  void _startLiveDetection() async {
    if (!mounted) return;

    while (mounted) {
      if (_isDetecting) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      _isDetecting = true;

      try {
        final XFile file = await _controller.takePicture();

        final Uint8List bytes = await file.readAsBytes();

        final image = img.decodeImage(bytes);

        if (image != null) {
          final x = image.width ~/ 2;
          final y = image.height ~/ 2;

          final pixel = image.getPixelSafe(x, y);

          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          final detectedColor = Color.fromARGB(255, r, g, b);

          final match = ColorUtils.getClosest(detectedColor);

          final hex =
              "#${r.toRadixString(16).padLeft(2, '0')}"
                      "${g.toRadixString(16).padLeft(2, '0')}"
                      "${b.toRadixString(16).padLeft(2, '0')}"
                  .toUpperCase();

          final rgb = "RGB($r, $g, $b)";

          if (mounted) {
            setState(() {
              _liveColor = detectedColor;

              _colorName = match.name;
              _match = match.match;

              _hexCode = hex;
              _rgbCode = rgb;
            });
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }

      _isDetecting = false;

      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  // ⚡ FLASH TOGGLE
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
    } catch (e) {
      debugPrint("Flash error: $e");
    }
  }

  // 💾 SAVE COLOR
  void _saveColor() {
    savedColors.add({
      "name": _colorName,
      "match": _match,
      "hex": _hexCode,
      "rgb": _rgbCode,
      "color": _liveColor,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Color Saved")));
  }

  // 📋 OPEN SAVED PAGE
  void _openSavedColors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedColorsScreen(savedColors: savedColors),
      ),
    );
  }

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
                // 🔥 TOP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Color Picker",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          _topButton(
                            icon: _flash ? Icons.flash_on : Icons.flash_off,
                            onTap: _toggleFlash,
                          ),

                          const SizedBox(width: 12),

                          _topButton(
                            icon: Icons.palette,
                            onTap: _openSavedColors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 📷 CAMERA AREA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Stack(
                        children: [
                          Positioned.fill(child: CameraPreview(_controller)),

                          // 🌫 LIGHT OVERLAY
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),

                          // 🎯 CENTER TARGET
                          const Center(
                            child: Icon(
                              Icons.center_focus_strong,
                              size: 90,
                              color: Colors.white,
                            ),
                          ),

                          // 🎨 LIVE COLOR PREVIEW
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: _liveColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🎨 INFO PANEL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 🎨 COLOR NAME
                            Text(
                              _colorName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 🎯 MATCH %
                            Text(
                              "Match ${_match.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 📋 INFO CARDS
                            Row(
                              children: [
                                Expanded(child: _infoCard("HEX", _hexCode)),

                                const SizedBox(width: 12),

                                Expanded(child: _infoCard("RGB", _rgbCode)),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // 💾 SAVE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: _saveColor,
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  "Save Color",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _liveColor,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
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

  // 🔘 TOP BUTTON
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
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }

  // 📋 INFO CARD
  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
