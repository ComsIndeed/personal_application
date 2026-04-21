import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/services/item_preview_cubit.dart';
import 'package:personal_application/core/widgets/asset_preview_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';

class ItemPreviewWidget extends StatefulWidget {
  const ItemPreviewWidget({super.key});

  @override
  State<ItemPreviewWidget> createState() => _ItemPreviewWidgetState();
}

class _ItemPreviewWidgetState extends State<ItemPreviewWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  Timer? _scrollTimer;
  Timer? _saveTimer;
  CommonNoteItem? _lastItem;
  String? _currentActiveId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _mainScrollController.addListener(_handleHeaderAnimation);
  }

  void _handleHeaderAnimation() {
    if (!_mainScrollController.hasClients) return;
    const threshold = 100.0;
    if (_mainScrollController.offset > threshold) {
      if (_headerAnimationController.status != AnimationStatus.forward &&
          _headerAnimationController.value < 1.0) {
        _headerAnimationController.forward();
      }
    } else {
      if (_headerAnimationController.status != AnimationStatus.reverse &&
          _headerAnimationController.value > 0.0) {
        _headerAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _scrollTimer?.cancel();
    _animationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    _titleController.dispose();
    _contentController.dispose();
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
    if (_mainScrollController.hasClients && _mainScrollController.offset != 0) {
      _mainScrollController.jumpTo(0);
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

  void _debounceSave(CommonNoteItem item) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveChanges(item);
    });
  }

  Future<void> _saveChanges(CommonNoteItem item) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title == (item.title ?? '') && content == (item.textContent ?? '')) {
      return;
    }

    final db = context.read<AppDatabase>();
    await (db.update(
      db.commonNoteItems,
    )..where((t) => t.id.equals(item.id))).write(
      CommonNoteItemsCompanion(
        title: Value(title.isEmpty ? null : title),
        textContent: Value(content.isEmpty ? null : content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemPreviewCubit, ItemPreviewState>(
      listener: (context, state) {
        final item = state.activeItem;
        if (item != null && item.id != _currentActiveId) {
          // If we had a previous item, save it before switching
          if (_currentActiveId != null && _lastItem != null) {
            _saveChanges(_lastItem!);
          }

          _currentActiveId = item.id;
          _titleController.text = item.title ?? '';
          _contentController.text = item.textContent ?? '';
          _resetScroll();
        } else if (item == null) {
          _stopScrolling();
          _currentActiveId = null;
        }

        if (state.hoveredItem != null && state.selectedItem == null) {
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
                    child: CustomScrollView(
                      controller: _mainScrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (displayItem.assetIds.isNotEmpty)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _NotePreviewHeaderDelegate(
                              item: displayItem,
                              isSelected: isSelected,
                              theme: theme,
                              carouselController: _scrollController,
                              titleController: _titleController,
                              animation: _headerAnimationController,
                              onScrollToItem: _scrollToItem,
                              onChanged: () => _debounceSave(displayItem),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (displayItem.assetIds.isEmpty) ...[
                                  TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      hintText: 'Add a title...',
                                      border: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hintStyle: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.black26,
                                          ),
                                    ),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                    onChanged: (_) =>
                                        _debounceSave(displayItem),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Add content...',
                                    border: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    hintStyle: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black26,
                                        ),
                                  ),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    height: 1.5,
                                  ),
                                  onChanged: (_) => _debounceSave(displayItem),
                                ),
                                const SizedBox(height: 100),
                              ],
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
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
            ),
            child: AssetPreviewWidget(
              key: ValueKey(widget.assetId),
              assetId: widget.assetId,
              fit: widget.isSelected ? BoxFit.contain : BoxFit.cover,
            ),
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

class _NotePreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  final CommonNoteItem item;
  final bool isSelected;
  final ThemeData theme;
  final ScrollController carouselController;
  final TextEditingController titleController;
  final Animation<double> animation;
  final Function(int, double) onScrollToItem;
  final VoidCallback onChanged;

  _NotePreviewHeaderDelegate({
    required this.item,
    required this.isSelected,
    required this.theme,
    required this.carouselController,
    required this.titleController,
    required this.animation,
    required this.onScrollToItem,
    required this.onChanged,
  });

  @override
  double get maxExtent => 420.0;

  @override
  double get minExtent => 160.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final isTriggered = shrinkOffset > 80.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(20),
              ),
            ),
          ),
          child: Stack(
            children: [
              // Media Section
              Positioned(
                top: isTriggered ? (70 * progress) : 0,
                left: 0,
                right: 0,
                height: isTriggered ? (320 - (240 * progress)) : 320,
                child: progress > 0.8 && isTriggered
                    ? const SizedBox() // Hide carousel completely when thumbnails are settled
                    : Opacity(
                        opacity: (1.0 - (progress * 2)).clamp(0.0, 1.0),
                        child: _buildMainCarousel(context),
                      ),
              ),
              // Procedural Staggered Thumbnails (appearing during transition)
              if (isTriggered && progress > 0.0)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: _buildCollapsedMedia(context, progress),
                ),
              // Title Field (Rendered last in the sequence: starts at 0.7 progress)
              Positioned(
                top: isTriggered ? (330 - (318 * progress)) : 330,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: isTriggered
                      ? ((progress - 0.7) / 0.3).clamp(0.0, 1.0)
                      : 1.0,
                  child: _buildTitleField(progress, isTriggered),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleField(double progress, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: titleController,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: 'Add a title...',
          border: InputBorder.none,
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          hintStyle:
              (isCollapsed
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black26,
                  ),
        ),
        style:
            (isCollapsed
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildMainCarousel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final itemWidth = isSelected ? width : height;

        return Stack(
          children: [
            ListView.builder(
              controller: carouselController,
              scrollDirection: Axis.horizontal,
              physics: isSelected
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final assetId = item.assetIds[index % item.assetIds.length];
                final targetWidth = isSelected ? width : height;
                final targetPadding = isSelected ? 0.0 : 8.0;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(end: targetWidth),
                  builder: (context, animWidth, child) {
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(end: targetPadding),
                      builder: (context, animPadding, child) {
                        return Container(
                          width: animWidth,
                          height: height,
                          padding: EdgeInsets.only(right: animPadding),
                          child: _HoverableMediaItem(
                            assetId: assetId,
                            isSelected: isSelected,
                            fit: isSelected ? BoxFit.contain : BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            if (isSelected && item.assetIds.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => onScrollToItem(-1, itemWidth),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => onScrollToItem(1, itemWidth),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCollapsedMedia(BuildContext context, double progress) {
    double currentOffset = carouselController.hasClients
        ? carouselController.offset
        : 0.0;
    double expandedItemWidth = isSelected ? 600 : 450;
    final int currentIndex =
        (currentOffset / expandedItemWidth).round() % item.assetIds.length;

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: item.assetIds.length,
        itemBuilder: (context, index) {
          final assetId = item.assetIds[index];
          final distance = (index - currentIndex).abs();
          // Sequence images first (0.0 to 0.7)
          final startAt = (distance * 0.05).clamp(0.0, 0.6);
          final endAt = (startAt + 0.3).clamp(0.0, 0.7);
          final itemProgress = ((progress - startAt) / (endAt - startAt)).clamp(
            0.0,
            1.0,
          );

          if (itemProgress <= 0) return const SizedBox.shrink();

          return Transform.translate(
            offset: Offset(
              -40 * (1.0 - itemProgress),
              30 * (1.0 - itemProgress),
            ),
            child: Transform.scale(
              scale: 0.6 + (0.4 * itemProgress),
              child: Opacity(
                opacity: itemProgress,
                child: Container(
                  width: 80,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withAlpha(30)
                          : Colors.black.withAlpha(30),
                      width: 1,
                    ),
                    boxShadow: [
                      if (itemProgress > 0.8)
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: AssetPreviewWidget(
                    assetId: assetId,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _NotePreviewHeaderDelegate oldDelegate) {
    return oldDelegate.item != item ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.theme != theme ||
        oldDelegate.animation != animation;
  }
}
