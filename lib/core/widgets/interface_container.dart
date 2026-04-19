import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:personal_application/main.dart';
import 'package:provider/provider.dart';

class InterfaceController extends ChangeNotifier {
  final WindowOverlayState? overlayState;

  bool _isVisible = false;
  double _width;
  double? _height;
  Alignment _alignment;

  InterfaceController({
    this.overlayState,
    bool initialVisible = false,
    double initialWidth = 420,
    double? initialHeight,
    Alignment initialAlignment = Alignment.centerRight,
  }) : _isVisible = initialVisible,
       _width = initialWidth,
       _height = initialHeight,
       _alignment = initialAlignment {
    overlayState?.addListener(notifyListeners);
  }

  bool get isVisible => overlayState?.isVisible ?? _isVisible;
  double get width => _width;
  double? get height => _height;
  Alignment get alignment => _alignment;

  void show() {
    if (overlayState != null) {
      overlayState!.open();
    } else {
      _isVisible = true;
      notifyListeners();
    }
  }

  void close() {
    if (overlayState != null) {
      overlayState!.close();
    } else {
      _isVisible = false;
      notifyListeners();
    }
  }

  void toggle() {
    if (isVisible) {
      close();
    } else {
      show();
    }
  }

  void updateSize({double? width, double? height}) {
    if (width != null) _width = width;
    if (height != null) _height = height;
    notifyListeners();
  }

  void updateAlignment(Alignment alignment) {
    _alignment = alignment;
    notifyListeners();
  }

  @override
  void dispose() {
    overlayState?.removeListener(notifyListeners);
    super.dispose();
  }
}

class InterfaceContainer extends StatefulWidget {
  final Widget Function(BuildContext context, InterfaceController controller)
  builder;
  final Widget Function(
    BuildContext context,
    InterfaceController controller,
    Widget container,
  )?
  outerBuilder;
  final InterfaceController? controller;
  final bool useSafeArea;
  final EdgeInsets? margin;

  const InterfaceContainer({
    super.key,
    required this.builder,
    this.outerBuilder,
    this.controller,
    this.useSafeArea = true,
    this.margin,
  });

  @override
  State<InterfaceContainer> createState() => _InterfaceContainerState();
}

class _InterfaceContainerState extends State<InterfaceContainer> {
  late InterfaceController _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = InterfaceController(
        overlayState: context.read<WindowOverlayState>(),
      );
    }
  }

  InterfaceController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _effectiveController,
      builder: (context, _) {
        final isVisible = _effectiveController.isVisible;

        Widget container = AnimatedContainer(
          duration: 350.ms,
          curve: Curves.easeOutCubic,
          width: _effectiveController.width,
          height: _effectiveController.height ?? double.infinity,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
            child: widget.builder(context, _effectiveController),
          ),
        );

        if (widget.outerBuilder != null) {
          container = widget.outerBuilder!(
            context,
            _effectiveController,
            container,
          );
        }

        EdgeInsets effectivePadding =
            widget.margin ?? const EdgeInsets.all(16.0);

        if (widget.useSafeArea && !kIsWeb && Platform.isWindows) {
          if (MediaQuery.of(context).padding.bottom == 0) {
            effectivePadding = effectivePadding.copyWith(
              bottom: effectivePadding.bottom + 48,
            );
          }
        }

        Widget content = Padding(
          padding: effectivePadding,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(1, 0),
            duration: 320.ms,
            curve: Curves.easeOutCubic,
            child: container,
          ),
        );

        Widget alignedContent = Align(
          alignment: _effectiveController.alignment,
          child: IntrinsicWidth(child: content),
        );

        if (widget.useSafeArea) {
          return SafeArea(child: alignedContent);
        }

        return alignedContent;
      },
    );
  }
}
