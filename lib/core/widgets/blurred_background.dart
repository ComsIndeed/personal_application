import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BackgroundSlice extends StatefulWidget {
  final ui.Image image;
  final Offset windowOffset;

  const BackgroundSlice({
    super.key,
    required this.image,
    required this.windowOffset,
  });

  @override
  State<BackgroundSlice> createState() => _BackgroundSliceState();
}

class _BackgroundSliceState extends State<BackgroundSlice> {
  Offset _globalOffset = Offset.zero;

  void _updateOffset() {
    if (!mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      if (_globalOffset != offset) {
        setState(() {
          _globalOffset = offset;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update offset after build to align the image slice
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOffset());

    final dpr = MediaQuery.of(context).devicePixelRatio;

    return OverflowBox(
      alignment: Alignment.topLeft,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        // Shift image by global position and window offset to pin it to the screen
        offset: -_globalOffset - widget.windowOffset,
        child: RawImage(
          image: widget.image,
          fit: BoxFit.none,
          alignment: Alignment.topLeft,
          scale: dpr,
          filterQuality: FilterQuality
              .low, // Performance over precision for blurred layers
        ),
      ),
    );
  }
}
