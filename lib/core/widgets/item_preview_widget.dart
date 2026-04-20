import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/services/item_preview_cubit.dart';
import 'package:personal_application/core/widgets/asset_preview_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ItemPreviewWidget extends StatefulWidget {
  const ItemPreviewWidget({super.key});

  @override
  State<ItemPreviewWidget> createState() => _ItemPreviewWidgetState();
}

class _ItemPreviewWidgetState extends State<ItemPreviewWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  Timer? _scrollTimer;
  CommonNoteItem? _lastItem;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    if (!_scrollController.hasClients) return;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) return;

        double nextOffset = _scrollController.offset + 0.5; // Constant speed
        if (nextOffset >= maxScroll) {
          nextOffset = 0; // Loop back
        }
        _scrollController.jumpTo(nextOffset);
      }
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
  }

  void _resetScroll() {
    _stopScrolling();
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToItem(int direction, double width) {
    if (!_scrollController.hasClients) return;

    // Snap to nearest item boundary to keep alignment
    final currentOffset = _scrollController.offset;
    final nearestItem = (currentOffset / width).round();
    final target = (nearestItem + direction) * width;

    _scrollController.animateTo(
      target.clamp(0, double.infinity),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemPreviewCubit, ItemPreviewState>(
      listener: (context, state) {
        if (state.selectedItem != null) {
          _resetScroll();
        } else if (state.hoveredItem != null) {
          // Give it a tiny delay to ensure the ListView is built
          Future.delayed(const Duration(milliseconds: 100), _startScrolling);
        } else {
          _stopScrolling();
        }
      },
      builder: (context, state) {
        final item = state.activeItem;
        final isVisible = item != null;

        // Cache the last item for exit animations
        if (item != null) {
          _lastItem = item;
        }

        if (_lastItem == null) return const SizedBox.shrink();

        final displayItem = _lastItem!;
        final isSelected = state.selectedItem != null;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Taskbar aware padding
        EdgeInsets effectivePadding = const EdgeInsets.all(16.0);
        if (!kIsWeb && Platform.isWindows) {
          if (MediaQuery.of(context).padding.bottom == 0) {
            effectivePadding = effectivePadding.copyWith(
              bottom: effectivePadding.bottom + 48,
            );
          }
        }

        return Positioned(
          left: 16,
          top: 16,
          bottom: effectivePadding.bottom,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(-1.2, 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main Preview Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 600 : 450,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(20)
                            : Colors.black.withAlpha(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 80 : 40),
                          blurRadius: 32,
                          offset: const Offset(8, 0),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (displayItem.assetIds.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white.withAlpha(20)
                                        : Colors.black.withAlpha(20),
                                  ),
                                ),
                              ),
                              child: _buildMediaSection(
                                displayItem,
                                isSelected,
                              ),
                            ),
                          ),
                        // Content Section
                        Expanded(
                          flex: displayItem.assetIds.isNotEmpty ? 2 : 1,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (displayItem.title != null &&
                                      displayItem.title!.isNotEmpty) ...[
                                    Text(
                                      displayItem.title!,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    displayItem.textContent ?? '',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Controls Section
                  AnimatedSlide(
                    offset: isSelected ? Offset.zero : const Offset(-1, 0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _buildControls(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaSection(CommonNoteItem item, bool isSelected) {
    if (item.assetIds.isEmpty) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withAlpha(5)
            : Colors.black.withAlpha(5),
        child: const Center(
          child: Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.white10,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionHeight = constraints.maxHeight;
        final sectionWidth = constraints.maxWidth;
        // When selected, items take full width for snapping.
        // When not selected, items are square (fixed width = fixed height).
        final itemWidth = isSelected ? sectionWidth : sectionHeight;

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: isSelected
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(), // Constant speed controlled by timer
              itemBuilder: (context, index) {
                // Infinite looping modulo
                final assetId = item.assetIds[index % item.assetIds.length];
                return Container(
                  width: itemWidth,
                  height: sectionHeight,
                  padding: EdgeInsets.only(right: isSelected ? 0 : 8),
                  child: _HoverableMediaItem(
                    assetId: assetId,
                    isSelected: isSelected,
                    fit: BoxFit.contain, // Requirement: fit the image inside
                  ),
                );
              },
            ),
            if (isSelected && item.assetIds.length > 1) ...[
              // Previous Arrow
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => _scrollToItem(-1, itemWidth),
                  ),
                ),
              ),
              // Next Arrow
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => _scrollToItem(1, itemWidth),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onPressed: () {},
          ),
          _ControlButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: Colors.redAccent,
            onPressed: () {},
          ),
          _ControlButton(
            icon: Icons.copy_all_rounded,
            label: 'Duplicate',
            onPressed: () {},
          ),
          _ControlButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onPressed: () {},
          ),
          const Divider(height: 16),
          _ControlButton(
            icon: Icons.close_rounded,
            label: 'Close',
            onPressed: () => context.read<ItemPreviewCubit>().clear(),
          ),
        ],
      ),
    );
  }
}

class _HoverableMediaItem extends StatefulWidget {
  final String assetId;
  final bool isSelected;
  final BoxFit fit;

  const _HoverableMediaItem({
    required this.assetId,
    required this.isSelected,
    this.fit = BoxFit.cover,
  });

  @override
  State<_HoverableMediaItem> createState() => _HoverableMediaItemState();
}

class _HoverableMediaItemState extends State<_HoverableMediaItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(widget.isSelected ? 100 : 60),
              border: Border(
                bottom: BorderSide(
                  color: widget.isSelected
                      ? Colors.white.withAlpha(40)
                      : Colors.white.withAlpha(15),
                  width: 2,
                ),
              ),
            ), // Darkened background with bottom shelf border
            child: AssetPreviewWidget(assetId: widget.assetId, fit: widget.fit),
          ),
          if (_isHovered)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HoverActionIcon(
                      icon: Icons.fullscreen_rounded,
                      label: 'Expand',
                      onPressed: () {},
                    ),
                    _HoverActionIcon(
                      icon: Icons.download_rounded,
                      label: 'Download',
                      onPressed: () {},
                    ),
                    _HoverActionIcon(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove from Note',
                      onPressed: () {},
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),
            ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CarouselArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withAlpha(160)
                : Colors.white.withAlpha(160),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withAlpha(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black.withAlpha(160),
            size: 28,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _HoverActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _HoverActionIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 20),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        hoverColor: Colors.white.withAlpha(40),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(
          icon,
          color: color ?? (isDark ? Colors.white70 : Colors.black54),
        ),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(12),
          hoverColor:
              color?.withAlpha(30) ??
              (isDark ? Colors.white10 : Colors.black.withAlpha(26)),
        ),
      ),
    );
  }
}
