import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:personal_application/core/services/app_prefs.dart';
import 'package:personal_application/core/widgets/blurred_background.dart';
import 'package:personal_application/main.dart';
import 'package:provider/provider.dart';

class InterfaceController extends ChangeNotifier {
  final WindowOverlayState? overlayState;

  bool _isVisible = false;
  double _width;
  double? _height;
  Alignment _alignment;
  BorderSide? _border;

  InterfaceController({
    this.overlayState,
    bool initialVisible = false,
    double initialWidth = 420,
    double? initialHeight,
    Alignment initialAlignment = Alignment.centerRight,
    BorderSide? initialBorder,
  }) : _isVisible = initialVisible,
       _width = initialWidth,
       _height = initialHeight,
       _alignment = initialAlignment,
       _border = initialBorder {
    overlayState?.addListener(notifyListeners);
  }

  bool get isVisible => overlayState?.isVisible ?? _isVisible;
  double get width => _width;
  double? get height => _height;
  Alignment get alignment => _alignment;
  BorderSide? get border => _border;

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
    _height = height; // Allow setting to null for wrap content
    notifyListeners();
  }

  void updateAlignment(Alignment alignment) {
    _alignment = alignment;
    notifyListeners();
  }

  void updateBorder(BorderSide? border) {
    _border = border;
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

  /// An optional builder to wrap the main decorated container with other widgets
  /// (like sidebars, navigation strips, or external overlays).
  /// This builder is called outside the decorative container but inside the animation/lifecycle.
  final Widget Function(
    BuildContext context,
    InterfaceController controller,
    Widget panel,
  )?
  layoutBuilder;

  final InterfaceController? controller;
  final bool useSafeArea;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? color;

  const InterfaceContainer({
    super.key,
    required this.builder,
    this.layoutBuilder,
    this.controller,
    this.useSafeArea = true,
    this.margin,
    this.borderRadius,
    this.color,
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

        Widget panel = GlassContainer(
          width: _effectiveController.width,
          height: _effectiveController.height,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          border: _effectiveController.border,
          color: widget.color,
          child: widget.builder(context, _effectiveController),
        );

        if (widget.layoutBuilder != null) {
          panel = widget.layoutBuilder!(context, _effectiveController, panel);
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
            child: panel,
          ),
        );

        Widget alignedContent = AnimatedAlign(
          alignment: _effectiveController.alignment,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
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

class GlassContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BorderSide? border;
  final Color? color;
  final Widget child;
  final bool showShadow;

  const GlassContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.color,
    required this.child,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Blur Layer (Surgical Slice of Pre-blurred Image)
            Positioned.fill(
              child: Consumer<WindowOverlayState>(
                builder: (context, overlayState, _) {
                  if (overlayState.blurredBgImage == null ||
                      !AppPrefs().dynamicBackdropEnabled) {
                    return const SizedBox.shrink();
                  }
                  return BackgroundSlice(
                    image: overlayState.blurredBgImage!,
                    windowOffset: overlayState.windowOffset,
                  );
                },
              ),
            ),
            // Tint and Border Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      color ??
                      (isDark
                          ? Colors.black.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.8)),
                  border: Border.fromBorderSide(
                    border ??
                        BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                ),
              ),
            ),
            // Content Layer
            child,
          ],
        ),
      ),
    );
  }
}
