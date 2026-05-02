import 'dart:math';
import 'package:flutter/material.dart';

class ColorMatch {
  final String name;
  final double match;
  final Color color;

  ColorMatch(this.name, this.match, this.color);
}

class ColorUtils {
  static List<ColorMatch> palette = [
    ColorMatch("Red", 0, Colors.red),
    ColorMatch("Green", 0, Colors.green),
    ColorMatch("Blue", 0, Colors.blue),
    ColorMatch("Yellow", 0, Colors.yellow),
    ColorMatch("Black", 0, Colors.black),
    ColorMatch("White", 0, Colors.white),
    ColorMatch("Orange", 0, Colors.orange),
    ColorMatch("Purple", 0, Colors.purple),
    ColorMatch("Pink", 0, Colors.pink),
    ColorMatch("Cyan", 0, Colors.cyan),
  ];

  static ColorMatch getClosest(Color target) {
    ColorMatch best = palette.first;
    double bestScore = 999999;

    for (var p in palette) {
      double diff = _distance(target, p.color);

      if (diff < bestScore) {
        bestScore = diff;
        best = p;
      }
    }

    double matchPercent = max(0, 100 - (bestScore / 441.67) * 100);

    return ColorMatch(best.name, matchPercent, best.color);
  }

  static double _distance(Color a, Color b) {
    return sqrt(
      pow(a.red - b.red, 2) +
          pow(a.green - b.green, 2) +
          pow(a.blue - b.blue, 2),
    );
  }
}
