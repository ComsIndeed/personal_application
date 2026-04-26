import 'package:flutter/material.dart';
import 'dart:async';

/// A configuration object for a single page in an [AppTab].
class AppTabPage<T> {
  final T id;
  final String initialTitle;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget Function(BuildContext context, AppTabController<T> controller)
  builder;

  const AppTabPage({
    required this.id,
    required this.initialTitle,
    this.leading,
    this.actions = const [],
    this.onBack,
    required this.builder,
  });
}

/// The state of the header for the current tab.
class AppTabHeader {
  final String title;
  final Widget? leading;
  final VoidCallback? onBack;
  final List<Widget> actions;

  AppTabHeader({
    required this.title,
    this.leading,
    this.onBack,
    this.actions = const [],
  });

  AppTabHeader copyWith({
    String? title,
    Widget? leading,
    bool clearLeading = false,
    VoidCallback? onBack,
    bool clearOnBack = false,
    List<Widget>? actions,
  }) {
    return AppTabHeader(
      title: title ?? this.title,
      leading: clearLeading ? null : (leading ?? this.leading),
      onBack: clearOnBack ? null : (onBack ?? this.onBack),
      actions: actions ?? this.actions,
    );
  }
}

/// Controller for [AppTab] to manage navigation and header state.
class AppTabController<T> extends ChangeNotifier {
  final List<AppTabPage<T>> pages;
  late int _currentIndex;
  late AppTabHeader _headerState;

  // Internal page controller for the vertical transitions
  final PageController pageController;

  AppTabController({required this.pages, int initialIndex = 0})
    : _currentIndex = initialIndex,
      pageController = PageController(initialPage: initialIndex) {
    _updateHeaderFromPage(pages[initialIndex]);
  }

  int get currentIndex => _currentIndex;
  T get currentId => pages[_currentIndex].id;
  AppTabHeader get headerState => _headerState;

  void _updateHeaderFromPage(AppTabPage<T> page) {
    _headerState = AppTabHeader(
      title: page.initialTitle,
      leading: page.leading,
      actions: page.actions,
      onBack: page.onBack,
    );
  }

  /// Animates to a specific page by its ID.
  void animateToId(T id) {
    final index = pages.indexWhere((p) => p.id == id);
    if (index != -1) animateToIndex(index);
  }

  /// Animates to a specific page by its index.
  void animateToIndex(int index) {
    if (index < 0 || index >= pages.length) return;
    if (_currentIndex == index) return;

    _currentIndex = index;
    _updateHeaderFromPage(pages[index]);

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    notifyListeners();
  }

  /// Updates the header state for the current page.
  /// Useful for sub-navigation or dynamic title changes.
  void updateHeader({
    String? title,
    Widget? leading,
    List<Widget>? actions,
    VoidCallback? onBack,
    bool clearLeading = false,
    bool clearOnBack = false,
  }) {
    // We use a microtask to avoid "setState during build" errors if called from build
    scheduleMicrotask(() {
      _headerState = _headerState.copyWith(
        title: title,
        leading: leading,
        actions: actions,
        onBack: onBack,
        clearLeading: leading == null ? true : clearLeading,
        clearOnBack: onBack == null ? true : clearOnBack,
      );
      notifyListeners();
    });
  }

  /// Resets the header to the current page's initial configuration.
  void resetHeader() {
    scheduleMicrotask(() {
      _updateHeaderFromPage(pages[_currentIndex]);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

/// A unified widget for managing a tabbed interface with a synchronized header.
class AppTab<T> extends StatefulWidget {
  final List<AppTabPage<T>> pages;
  final AppTabController<T>? controller;
  final List<Widget> globalActions; // Actions that can be relocated
  final Widget?
  trailingHeaderWidget; // Always stays in Row 1 (e.g. Close button)

  const AppTab({
    super.key,
    required this.pages,
    this.controller,
    this.globalActions = const [],
    this.trailingHeaderWidget,
  });

  @override
  State<AppTab<T>> createState() => _AppTabState<T>();
}

class _AppTabState<T> extends State<AppTab<T>> {
  late AppTabController<T> _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = AppTabController<T>(pages: widget.pages);
    }
  }

  AppTabController<T> get _effectiveController =>
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
        final header = _effectiveController.headerState;

        return Column(
          children: [
            // Unified Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;

                    // Estimate widths for responsiveness
                    // Margins (32) + Leading (52 if exists) + Close/Trailing (~52) + Buffers
                    final double fixedWidths =
                        32 +
                        (header.leading != null || header.onBack != null
                            ? 52
                            : 0) +
                        60;

                    // Measure title width
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: header.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    )..layout();

                    final titleWidth = textPainter.width;

                    // Combine tab actions and global actions
                    final allRelocatableActions = [
                      ...header.actions,
                      ...widget.globalActions,
                    ];

                    // Separate actions by type
                    // Note: We check specifically for Expanded/Flexible or widgets that likely contain them
                    final flexibleActions = allRelocatableActions
                        .where((a) => a is Expanded || a is Flexible)
                        .toList();
                    final staticActions = allRelocatableActions
                        .where((a) => a is! Expanded && a is! Flexible)
                        .toList();

                    // Estimate static actions width
                    final double staticActionsWidth =
                        staticActions.length * 44.0;

                    // Determine if buttons need to stack (overflowing title)
                    final bool buttonsNeedStack =
                        staticActions.isNotEmpty &&
                        (titleWidth + staticActionsWidth + fixedWidths >
                            availableWidth);

                    // Determine if flexible actions exist
                    final bool hasFlexible = flexibleActions.isNotEmpty;

                    // The header is in "stacked mode" if we have flexible actions OR overflowing buttons
                    final bool isStackedMode = hasFlexible || buttonsNeedStack;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Leading/Back Section
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SizeTransition(
                                      sizeFactor: animation,
                                      axis: Axis.horizontal,
                                      axisAlignment: -1,
                                      child: child,
                                    ),
                                  ),
                              child:
                                  (header.leading != null ||
                                      header.onBack != null)
                                  ? Padding(
                                      key: const ValueKey('header_leading'),
                                      padding: const EdgeInsets.only(right: 12),
                                      child:
                                          header.leading ??
                                          IconButton(
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                              size: 20,
                                            ),
                                            onPressed: header.onBack,
                                          ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Title Section
                            Expanded(
                              child: Text(
                                header.title,
                                key: ValueKey('title_${header.title}'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                            ),

                            // Inline Static Actions (only if they fit and aren't forced down)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    axis: Axis.horizontal,
                                    axisAlignment: 1,
                                    child: child,
                                  ),
                                );
                              },
                              child:
                                  !buttonsNeedStack && staticActions.isNotEmpty
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      key: const ValueKey('inline_actions'),
                                      children: [
                                        const SizedBox(width: 8),
                                        ...staticActions,
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Trailing Section
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SizeTransition(
                                      sizeFactor: animation,
                                      axis: Axis.horizontal,
                                      axisAlignment: 1,
                                      child: child,
                                    ),
                                  ),
                              child: (widget.trailingHeaderWidget != null)
                                  ? Padding(
                                      key: const ValueKey('header_trailing'),
                                      padding: const EdgeInsets.only(left: 8),
                                      child: widget.trailingHeaderWidget!,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),

                        // Stacked Actions Row
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.5),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: isStackedMode
                              ? Padding(
                                  key: const ValueKey('stacked_actions'),
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      ...flexibleActions,
                                      if (buttonsNeedStack) ...staticActions,
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Colors.white10,
            ),

            // Content Area
            Expanded(
              child: PageView(
                controller: _effectiveController.pageController,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                children: widget.pages
                    .map((page) => page.builder(context, _effectiveController))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
