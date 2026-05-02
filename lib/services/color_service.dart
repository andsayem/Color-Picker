import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../models/color_info.dart';

class ColorService {
  /// 🎨 Get color from image at x,y position
  static ColorInfo getColorFromImage(img.Image image, int x, int y) {
    x = x.clamp(0, image.width - 1);
    y = y.clamp(0, image.height - 1);

    final pixel = image.getPixelSafe(x, y);

    return ColorInfo(
      red: pixel.r.toInt(),
      green: pixel.g.toInt(),
      blue: pixel.b.toInt(),
      alpha: pixel.a.toInt(),
    );
  }

  /// 🖼 Decode image from bytes
  static img.Image? decodeImage(List<int> bytes) {
    try {
      final Uint8List uint8Bytes = Uint8List.fromList(bytes);
      return img.decodeImage(uint8Bytes);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }
}
