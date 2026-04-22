import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

class _BackgroundSliceState extends State<BackgroundSlice>
    with SingleTickerProviderStateMixin {
  Offset _currentOffset = Offset.zero;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final newOffset = box.localToGlobal(Offset.zero);
        if (_currentOffset != newOffset) {
          setState(() {
            _currentOffset = newOffset;
          });
        }
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return CustomPaint(
      painter: _BackgroundSlicePainter(
        image: widget.image,
        // Calculate where the image should start relative to this widget
        // We shift the image back by the widget's global position and the OS window offset
        drawOffset: -_currentOffset - widget.windowOffset,
        scale: dpr,
      ),
    );
  }
}

class _BackgroundSlicePainter extends CustomPainter {
  final ui.Image image;
  final Offset drawOffset;
  final double scale;

  _BackgroundSlicePainter({
    required this.image,
    required this.drawOffset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = ui.FilterQuality.low;

    // Draw the image at the calculated offset.
    // This effectively 'crops' the full blurred image to the widget's area.
    canvas.save();
    canvas.translate(drawOffset.dx, drawOffset.dy);
    canvas.scale(1.0 / scale);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundSlicePainter oldDelegate) {
    return oldDelegate.drawOffset != drawOffset || oldDelegate.image != image;
  }
}
