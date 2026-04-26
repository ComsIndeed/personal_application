import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/widgets/asset_preview_widget.dart';
import 'package:personal_application/core/services/item_preview_cubit.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/constants/app_tab_id.dart';
import 'package:personal_application/core/widgets/app_tab.dart';
import 'package:personal_application/interfaces/tabs/brain_dump/brain_dump_cubit.dart';

class BrainDumpItemWidget extends StatefulWidget {
  final CommonNoteItem item;
  final bool isPending;

  const BrainDumpItemWidget({
    super.key,
    required this.item,
    this.isPending = false,
  });

  @override
  State<BrainDumpItemWidget> createState() => _BrainDumpItemWidgetState();
}

class _BrainDumpItemWidgetState extends State<BrainDumpItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final text = widget.item.textContent ?? '';
    final assetIds = widget.item.assetIds;
    final isSingleMedia = assetIds.length == 1 && text.length < 250;

    final previewCubit = context.read<ItemPreviewCubit>();
    final isSelected =
        context.watch<ItemPreviewCubit>().state.selectedItem == widget.item;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        previewCubit.setHoveredItem(widget.item);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        previewCubit.setHoveredItem(null);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              previewCubit.setSelectedItem(isSelected ? null : widget.item),
          borderRadius: BorderRadius.circular(16),
          child:
              AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ((_isHovered || isSelected)
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF0F172A).withAlpha(128))
                          : ((_isHovered || isSelected)
                                ? Colors.white
                                : Colors.white.withAlpha(200)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? ((_isHovered || isSelected)
                                  ? Colors.white.withAlpha(80)
                                  : Colors.white.withAlpha(10))
                            : ((_isHovered || isSelected)
                                  ? Colors.black.withAlpha(40)
                                  : Colors.black.withAlpha(10)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: (_isHovered || isSelected)
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 50 : 20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: widget.isPending ? 0.6 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isSingleMedia
                              ? _buildSingleMediaLayout(context)
                              : _buildTextHeavyLayout(context),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child:
                                (_isHovered || isSelected) && !widget.isPending
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        _CategorySquircle(
                                          color: Colors.redAccent,
                                          tooltip: 'Important',
                                          icon: Icons.priority_high_rounded,
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now().add(
                                                const Duration(days: 1),
                                              ),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365),
                                              ),
                                              helpText: 'Select Deadline',
                                            );

                                            if (date == null) return;
                                            if (!context.mounted) return;

                                            context
                                                .read<BrainDumpCubit>()
                                                .promoteToTask(
                                                  widget.item,
                                                  TaskType.important,
                                                  dueDate: date,
                                                );
                                            context
                                                .read<
                                                  AppTabController<AppTabId>
                                                >()
                                                .animateToId(AppTabId.sprints);
                                          },
                                        ),
                                        _CategorySquircle(
                                          color: Colors.blueAccent,
                                          tooltip: 'Admin',
                                          onTap: () {
                                            context
                                                .read<BrainDumpCubit>()
                                                .promoteToTask(
                                                  widget.item,
                                                  TaskType.admin,
                                                );
                                            context
                                                .read<
                                                  AppTabController<AppTabId>
                                                >()
                                                .animateToId(AppTabId.sprints);
                                          },
                                        ),
                                        _CategorySquircle(
                                          color: Colors.purpleAccent,
                                          tooltip: 'Fun',
                                          onTap: () {
                                            context
                                                .read<BrainDumpCubit>()
                                                .promoteToTask(
                                                  widget.item,
                                                  TaskType.fun,
                                                );
                                            context
                                                .read<
                                                  AppTabController<AppTabId>
                                                >()
                                                .animateToId(AppTabId.sprints);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _ActionButton(
                                          icon: Icons.delete_outline_rounded,
                                          onPressed: () {
                                            context
                                                .read<BrainDumpCubit>()
                                                .deleteItem(widget.item.id);
                                          },
                                          tooltip: 'Delete',
                                        ),
                                        const Spacer(),
                                        _ActionButton(
                                          icon: Icons.copy_rounded,
                                          onPressed: () {},
                                          tooltip: 'Copy Text',
                                        ),
                                        _ActionButton(
                                          icon: Icons.edit_rounded,
                                          onPressed: () {},
                                          tooltip: 'Edit',
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(
                                    width: double.infinity,
                                    height: 0,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(target: widget.isPending ? 1 : 0)
                  .shimmer(
                    duration: 1.5.seconds,
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
                  ),
        ),
      ),
    );
  }

  Widget _buildSingleMediaLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Media Part
          SizedBox(
            width: 120,
            height: 120,
            child: AssetPreviewWidget(assetId: widget.item.assetIds.first),
          ),
          // Content Part
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.item.title != null &&
                      widget.item.title!.isNotEmpty)
                    Text(
                      widget.item.title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.item.textContent != null &&
                      widget.item.textContent!.isNotEmpty)
                    Text(
                      widget.item.textContent!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextHeavyLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.title != null && widget.item.title!.isNotEmpty) ...[
            Text(
              widget.item.title!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
          ],
          if (widget.item.textContent != null &&
              widget.item.textContent!.isNotEmpty) ...[
            Text(
              widget.item.textContent!,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
              maxLines: widget.item.assetIds.isEmpty ? 10 : 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.item.assetIds.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.item.assetIds.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AssetPreviewWidget(
                        assetId: widget.item.assetIds[index],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(widget.item.createdAt);

    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 4),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySquircle extends StatelessWidget {
  final Color color;
  final String tooltip;
  final IconData? icon;
  final VoidCallback onTap;

  const _CategorySquircle({
    required this.color,
    required this.tooltip,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Promote to $tooltip',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: icon != null
              ? Center(child: Icon(icon, size: 10, color: Colors.white))
              : null,
        ),
      ),
    );
  }
}
