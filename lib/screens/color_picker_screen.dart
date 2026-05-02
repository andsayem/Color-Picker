import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../models/color_info.dart';
import '../services/color_service.dart';

class ColorPickerScreen extends StatefulWidget {
  final List<int> imageBytes;

  const ColorPickerScreen({super.key, required this.imageBytes});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  img.Image? _image;
  ColorInfo? _selectedColor;

  final GlobalKey _imageKey = GlobalKey();
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _image = ColorService.decodeImage(widget.imageBytes);
  }

  void _onTapDown(TapDownDetails details) {
    if (_image == null) return;

    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final local = box.globalToLocal(details.globalPosition);

    // 🎯 Convert screen → image coordinate
    int x = (local.dx / size.width * _image!.width).toInt();
    int y = (local.dy / size.height * _image!.height).toInt();

    // 🔥 SAFE BOUNDARY (CRASH PREVENTION)
    x = x.clamp(0, _image!.width - 1);
    y = y.clamp(0, _image!.height - 1);

    final color = ColorService.getColorFromImage(_image!, x, y);

    setState(() {
      _selectedColor = color;
      _tapPosition = local;
    });
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Copied: $text")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Color Picker"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),

      body: _image == null
          ? const Center(
              child: Text(
                "Failed to load image",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                // 🖼 IMAGE AREA
                Expanded(
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    child: Stack(
                      children: [
                        Center(
                          child: Image.memory(
                            Uint8List.fromList(widget.imageBytes),
                            key: _imageKey,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // 🎯 Tap indicator
                        if (_tapPosition != null)
                          Positioned(
                            left: _tapPosition!.dx - 10,
                            top: _tapPosition!.dy - 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 🎨 COLOR PANEL
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _selectedColor == null
                      ? _buildHint()
                      : _buildColorInfo(),
                ),
              ],
            ),
    );
  }

  // 🔰 Hint UI
  Widget _buildHint() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app, color: Colors.white54, size: 50),
        SizedBox(height: 10),
        Text(
          "Tap on image to pick color",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  // 🎨 Color UI
  Widget _buildColorInfo() {
    final color = _selectedColor!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(color.toColorValue()),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white),
          ),
        ),

        const SizedBox(height: 16),

        _buildTile("HEX", color.toHex()),
        _buildTile("RGB", color.toRgb()),
        _buildTile("RGBA", color.toRgba()),
      ],
    );
  }

  // 📋 Info tile
  Widget _buildTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TEXT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // COPY
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () => _copy(value),
          ),
        ],
      ),
    );
  }
}
