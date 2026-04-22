import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BlurredBackground extends StatelessWidget {
  final ui.Image? image;
  final Offset windowOffset;
  final bool isVisible;

  const BlurredBackground({
    super.key,
    required this.image,
    required this.windowOffset,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox.shrink();

    // Use devicePixelRatio to map physical screenshot pixels to logical Flutter pixels
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Transform.translate(
        offset: -windowOffset,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: RawImage(
            image: image,
            fit: BoxFit.none,
            alignment: Alignment.topLeft,
            scale: dpr, // Correctly scale physical pixels to logical pixels
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
