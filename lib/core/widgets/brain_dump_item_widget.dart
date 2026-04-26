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
  bool _isDatePromptVisible = false;

  @override
  void didUpdateWidget(BrainDumpItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _isDatePromptVisible = false;
    }
  }

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
                                (_isHovered ||
                                        isSelected ||
                                        _isDatePromptVisible) &&
                                    !widget.isPending
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_isDatePromptVisible)
                                        Padding(
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
                                                onTap: () {
                                                  setState(
                                                    () => _isDatePromptVisible =
                                                        true,
                                                  );
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
                                                        AppTabController<
                                                          AppTabId
                                                        >
                                                      >()
                                                      .animateToId(
                                                        AppTabId.sprints,
                                                      );
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
                                                        AppTabController<
                                                          AppTabId
                                                        >
                                                      >()
                                                      .animateToId(
                                                        AppTabId.sprints,
                                                      );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              _ActionButton(
                                                icon: Icons
                                                    .delete_outline_rounded,
                                                onPressed: () {
                                                  context
                                                      .read<BrainDumpCubit>()
                                                      .deleteItem(
                                                        widget.item.id,
                                                      );
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
                                        ),
                                      if (_isDatePromptVisible)
                                        _DatePromptWidget(
                                          onDateSelected: (date) {
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
                                          onCancel: () {
                                            setState(
                                              () =>
                                                  _isDatePromptVisible = false,
                                            );
                                          },
                                        ),
                                    ],
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

class _DatePromptWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final VoidCallback onCancel;

  const _DatePromptWidget({
    required this.onDateSelected,
    required this.onCancel,
  });

  @override
  State<_DatePromptWidget> createState() => _DatePromptWidgetState();
}

class _DatePromptWidgetState extends State<_DatePromptWidget> {
  int _selectedTabIndex = 0; // 0 for 3-weeks, 1 for full calendar

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _TabButton(
                label: 'Quick Pick',
                isSelected: _selectedTabIndex == 0,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Calendar',
                isSelected: _selectedTabIndex == 1,
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedTabIndex == 0
                ? _WeeklyDateSlider(onDateSelected: widget.onDateSelected)
                : _FullCalendarPlaceholder(
                    onDateSelected: widget.onDateSelected,
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withAlpha(30)
                    : Colors.black.withAlpha(20))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }
}

class _WeeklyDateSlider extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const _WeeklyDateSlider({required this.onDateSelected});

  @override
  State<_WeeklyDateSlider> createState() => _WeeklyDateSliderState();
}

class _WeeklyDateSliderState extends State<_WeeklyDateSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start of the week (assuming Sunday start)
    final startOfThisWeek = today.subtract(Duration(days: today.weekday % 7));

    const weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate current range for the indicator
    final firstDay = startOfThisWeek.add(Duration(days: _currentPage * 21));
    final lastDay = firstDay.add(const Duration(days: 20));
    final dateRangeStr =
        '${DateFormat('MMM d').format(firstDay)} - ${DateFormat('MMM d').format(lastDay)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels
                .map(
                  (l) => Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(
          height: 240, // Increased for 3 rows
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: 5, // 5 pages of 3 weeks each
            itemBuilder: (context, pageIndex) {
              final pageStartDate = startOfThisWeek.add(
                Duration(days: pageIndex * 21),
              );
              return Column(
                children: List.generate(3, (rowIndex) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final dayIndex = rowIndex * 7 + colIndex;
                        final day = pageStartDate.add(Duration(days: dayIndex));
                        final isPast = day.isBefore(today);
                        final isToday = day.isAtSameMomentAs(today);
                        final isEven = dayIndex % 2 == 0;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: _DateTile(
                              date: day,
                              isPast: isPast,
                              isToday: isToday,
                              isEven: isEven,
                              onTap: isPast
                                  ? null
                                  : () => widget.onDateSelected(day),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                dateRangeStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _currentPage == index ? 12 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final bool isPast;
  final bool isToday;
  final bool isEven;
  final VoidCallback? onTap;

  const _DateTile({
    required this.date,
    required this.isPast,
    required this.isToday,
    required this.isEven,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthStr = DateFormat('MMM').format(date).toUpperCase();
    final dayNum = date.day.toString();

    Widget content = Container(
      decoration: BoxDecoration(
        color: isToday
            ? Colors.redAccent.withAlpha(40)
            : (isPast
                  ? Colors.transparent
                  : (isDark
                        ? (isEven
                              ? Colors.white.withAlpha(8)
                              : Colors.white.withAlpha(3))
                        : (isEven
                              ? Colors.black.withAlpha(8)
                              : Colors.black.withAlpha(3)))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Colors.redAccent.withAlpha(100)
              : (isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(10)),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            monthStr,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isPast
                  ? (isDark ? Colors.white12 : Colors.black12)
                  : (isToday
                        ? Colors.redAccent.withAlpha(180)
                        : (isDark ? Colors.white24 : Colors.black26)),
            ),
          ),
          Text(
            dayNum,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: isPast
                  ? (isDark ? Colors.white12 : Colors.black12)
                  : (isToday
                        ? Colors.redAccent
                        : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      if (!isToday) {
        content = content
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.02, 1.02),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            )
            .custom(
              duration: 2.seconds,
              builder: (context, value, child) {
                return Opacity(opacity: 0.8 + (value * 0.2), child: child);
              },
            );
      }
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }
}

class _FullCalendarPlaceholder extends StatelessWidget {
  final Function(DateTime) onDateSelected;

  const _FullCalendarPlaceholder({required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 32,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: 'Select Deadline',
              );
              if (date != null) onDateSelected(date);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open System Picker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withAlpha(40),
              foregroundColor: Colors.blueAccent,
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
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
  final VoidCallback onTap;

  const _CategorySquircle({
    required this.color,
    required this.tooltip,
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
        ),
      ),
    );
  }
}
