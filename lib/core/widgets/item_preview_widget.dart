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
                        // Media Section
                        if (displayItem.assetIds.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: _buildMediaSection(displayItem),
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

  Widget _buildMediaSection(CommonNoteItem item) {
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

    // Scrollable horizontal list
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics:
          const NeverScrollableScrollPhysics(), // Constant speed controlled by timer
      itemBuilder: (context, index) {
        // Simple infinite looping by modulo
        final assetId = item.assetIds[index % item.assetIds.length];
        return Container(
          width: 380, // Allow "other images seen kinda"
          margin: const EdgeInsets.only(right: 8),
          child: AssetPreviewWidget(assetId: assetId, fit: BoxFit.cover),
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
