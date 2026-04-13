import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // To access WindowOverlayState

class InterfaceController {
  final WindowOverlayState overlayState;
  InterfaceController(this.overlayState);

  void close() => overlayState.close();
  void toggle() => overlayState.toggle();
}

class InterfaceContainer extends StatelessWidget {
  final Widget Function(BuildContext context, InterfaceController controller)
  builder;
  final bool isVisible;
  final InterfaceController? controller;

  const InterfaceContainer({
    super.key,
    required this.builder,
    required this.isVisible,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? InterfaceController(context.read<WindowOverlayState>());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).cardColor,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: builder(context, effectiveController),
                ),
              )
              .animate(target: isVisible ? 1 : 0)
              .slideX(
                begin: 1,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 320.ms,
              ),
    );
  }
}
