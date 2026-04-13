import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:personal_application/main.dart';
import 'package:provider/provider.dart';

class InterfaceController {
  final WindowOverlayState overlayState;
  InterfaceController(this.overlayState);

  void close() => overlayState.close();
  void toggle() => overlayState.toggle();
}

class InterfaceContainer extends StatelessWidget {
  final Widget Function(BuildContext context, InterfaceController controller)
  builder;
  final Widget Function(
    BuildContext context,
    InterfaceController controller,
    Widget container,
  )?
  outerBuilder;
  final bool isVisible;
  final InterfaceController? controller;
  final bool useSafeArea;

  const InterfaceContainer({
    super.key,
    required this.builder,
    required this.isVisible,
    this.outerBuilder,
    this.controller,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? InterfaceController(context.read<WindowOverlayState>());

    Widget container = Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: builder(context, effectiveController),
      ),
    );

    if (outerBuilder != null) {
      container = outerBuilder!(context, effectiveController, container);
    }

    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: container
          .animate(target: isVisible ? 1 : 0)
          .slideX(
            begin: 1,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 320.ms,
          ),
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }

    return content;
  }
}
