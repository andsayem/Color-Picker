class ColorInfo {
  final int red;
  final int green;
  final int blue;
  final int alpha;

  ColorInfo({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 255,
  });

  /// Convert to HEX string (e.g., #FF5733)
  String toHex() {
    return '#${red.toRadixString(16).padLeft(2, '0').toUpperCase()}${green.toRadixString(16).padLeft(2, '0').toUpperCase()}${blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  /// Get RGB string (e.g., rgb(255, 87, 51))
  String toRgb() {
    return 'rgb($red, $green, $blue)';
  }

  /// Get RGBA string (e.g., rgba(255, 87, 51, 1.0))
  String toRgba() {
    final alphaValue = (alpha / 255).toStringAsFixed(2);
    return 'rgba($red, $green, $blue, $alphaValue)';
  }

  /// Convert to Color object
  int toColorValue() {
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}
