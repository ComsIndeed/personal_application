import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/services/item_preview_cubit.dart';
import 'package:personal_application/core/widgets/note_markdown_editor.dart';

class SprintTaskItemWidget extends StatefulWidget {
  final CommonNoteItem task;
  final bool isDark;
  final VoidCallback? onStart;
  final bool active;
  final VoidCallback? onComplete;

  const SprintTaskItemWidget({
    super.key,
    required this.task,
    required this.isDark,
    this.onStart,
    this.active = false,
    this.onComplete,
  });

  @override
  State<SprintTaskItemWidget> createState() => _SprintTaskItemWidgetState();
}

class _SprintTaskItemWidgetState extends State<SprintTaskItemWidget>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late final TextEditingController _logController;

  @override
  void initState() {
    super.initState();
    _logController = TextEditingController();
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.completionStatus ?? false;
    final previewCubit = context.read<ItemPreviewCubit>();
    final isSelected =
        context.watch<ItemPreviewCubit>().state.selectedItem == widget.task;

    final showOverlay = (_isHovered || isSelected || widget.active);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        previewCubit.setHoveredItem(widget.task);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        previewCubit.setHoveredItem(null);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              previewCubit.setSelectedItem(isSelected ? null : widget.task),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? ((_isHovered || isSelected || widget.active)
                        ? const Color(0xFF1E293B)
                        : (widget.active
                              ? Colors.blue.withAlpha(30)
                              : const Color(0xFF0F172A).withAlpha(128)))
                  : ((_isHovered || isSelected || widget.active)
                        ? Colors.white
                        : (widget.active
                              ? Colors.blue.withAlpha(10)
                              : Colors.white.withAlpha(200))),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark
                    ? ((_isHovered || isSelected || widget.active)
                          ? Colors.white.withAlpha(80)
                          : (widget.active
                                ? Colors.blue.withAlpha(50)
                                : Colors.white.withAlpha(40)))
                    : ((_isHovered || isSelected || widget.active)
                          ? Colors.black.withAlpha(40)
                          : (widget.active
                                ? Colors.blue.withAlpha(50)
                                : Colors.black.withAlpha(30))),
                width: (isSelected || widget.active) ? 2 : 1,
              ),
              boxShadow: (_isHovered || isSelected || widget.active)
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(widget.isDark ? 50 : 20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getGroupColor(widget.task.group),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getGroupIcon(widget.task.group),
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.task.title != null &&
                                    widget.task.title!.isNotEmpty)
                                  Text(
                                    widget.task.title!,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? (widget.isDark
                                                ? Colors.white38
                                                : Colors.black38)
                                          : (widget.isDark
                                                ? Colors.white
                                                : Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isCompleted &&
                              !widget.active &&
                              !_isHovered &&
                              !isSelected)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                                size: 24,
                                color: Colors.blueAccent,
                              ),
                              onPressed: widget.onStart ?? () {},
                            ),
                          if (widget.active && !_isHovered && !isSelected)
                            const Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      IgnorePointer(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: showOverlay ? 80 : 20,
                          ),
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black, Colors.transparent],
                                stops: [0.7, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstIn,
                            child: NoteMarkdownEditor(
                              initialMarkdown:
                                  widget.task.textContent ?? "No description",
                              onSave: (_) async {},
                              readOnly: true,
                              shrinkWrap: true,
                              isCard: true,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFooter(context),
                      if (showOverlay) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 12),
                        _buildLogBox(context),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: showOverlay
                      ? _buildTickboxOverlay(context)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = widget.isDark;
    final dueDate = widget.task.dueDate;

    return Row(
      children: [
        if (dueDate != null) ...[
          Icon(
            Icons.calendar_today_rounded,
            size: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d, h:mm a').format(dueDate),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (widget.task.estTime != null) ...[
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 4),
          Text(
            "${(widget.task.estTime! / 60).ceil()}m",
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogBox(BuildContext context) {
    return TextField(
      controller: _logController,
      style: TextStyle(
        fontSize: 13,
        color: widget.isDark ? Colors.white : Colors.black,
      ),
      maxLines: 1,
      onTap: () {
        final cubit = context.read<ItemPreviewCubit>();
        if (cubit.state.selectedItem != widget.task) {
          cubit.setSelectedItem(widget.task);
        }
      },
      decoration: InputDecoration(
        hintText: 'Log session...',
        hintStyle: TextStyle(
          fontSize: 13,
          color: widget.isDark ? Colors.white24 : Colors.black26,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isDark
                ? Colors.white.withAlpha(26)
                : Colors.black.withAlpha(26),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isDark
                ? Colors.white.withAlpha(26)
                : Colors.black.withAlpha(26),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
        filled: true,
        fillColor: widget.isDark
            ? Colors.white.withAlpha(5)
            : Colors.black.withAlpha(5),
      ),
      onSubmitted: (_) {
        // Do nothing for now as requested
      },
    );
  }

  Widget _buildTickboxOverlay(BuildContext context) {
    final isCompleted = widget.task.completionStatus ?? false;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withAlpha(40)
              : Colors.black.withAlpha(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.active && widget.onComplete != null)
            _ActionButton(
              icon: Icons.check_circle_outline_rounded,
              onPressed: widget.onComplete!,
              tooltip: 'Complete Task',
              color: Colors.greenAccent,
            ),
          if (!widget.active && !isCompleted)
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              onPressed: widget.onStart ?? () {},
              tooltip: 'Start Task',
              color: Colors.blueAccent,
            ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.9,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isCompleted,
                activeColor: Colors.blueAccent,
                side: BorderSide(
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  if (val != null && widget.onComplete != null) {
                    widget.onComplete!();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(String? group) {
    if (group == null) return Colors.grey;
    switch (group.toLowerCase()) {
      case 'messenger':
        return const Color(0xFF00B2FF);
      case 'email':
      case 'gmail':
        return const Color(0xFFEA4335);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'school':
        return const Color(0xFF4CAF50);
      case 'google docs':
        return const Color(0xFF4285F4);
      case 'canva':
        return const Color(0xFF8B3DFF);
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getGroupIcon(String? group) {
    if (group == null) return Icons.blur_on_rounded;
    switch (group.toLowerCase()) {
      case 'messenger':
        return Icons.messenger_rounded;
      case 'email':
      case 'gmail':
        return Icons.email_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'school':
        return Icons.book_rounded;
      case 'google docs':
        return Icons.description_rounded;
      case 'canva':
        return Icons.palette_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 20,
              color: color ?? (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ),
    );
  }
}
