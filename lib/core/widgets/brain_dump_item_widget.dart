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
  TaskType? _pendingTaskType;

  @override
  void didUpdateWidget(BrainDumpItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _isDatePromptVisible = false;
      _pendingTaskType = null;
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
                                                  setState(() {
                                                    _pendingTaskType =
                                                        TaskType.important;
                                                    _isDatePromptVisible = true;
                                                  });
                                                },
                                              ),
                                              _CategorySquircle(
                                                color: Colors.blueAccent,
                                                tooltip: 'Admin',
                                                onTap: () {
                                                  setState(() {
                                                    _pendingTaskType =
                                                        TaskType.admin;
                                                    _isDatePromptVisible = true;
                                                  });
                                                },
                                              ),
                                              _CategorySquircle(
                                                color: Colors.purpleAccent,
                                                tooltip: 'Fun',
                                                onTap: () {
                                                  setState(() {
                                                    _pendingTaskType =
                                                        TaskType.fun;
                                                    _isDatePromptVisible = true;
                                                  });
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
                                          onConfirmed: (date, time) {
                                            DateTime? finalDueDate;
                                            if (date != null) {
                                              finalDueDate = DateTime(
                                                date.year,
                                                date.month,
                                                date.day,
                                                time?.hour ?? 0,
                                                time?.minute ?? 0,
                                              );
                                            }

                                            context
                                                .read<BrainDumpCubit>()
                                                .promoteToTask(
                                                  widget.item,
                                                  _pendingTaskType ??
                                                      TaskType.important,
                                                  dueDate: finalDueDate,
                                                );

                                            context
                                                .read<
                                                  AppTabController<AppTabId>
                                                >()
                                                .animateToId(AppTabId.sprints);
                                          },
                                          onCancel: () {
                                            setState(() {
                                              _isDatePromptVisible = false;
                                              _pendingTaskType = null;
                                            });
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
  final Function(DateTime?, TimeOfDay?) onConfirmed;
  final VoidCallback onCancel;

  const _DatePromptWidget({required this.onConfirmed, required this.onCancel});

  @override
  State<_DatePromptWidget> createState() => _DatePromptWidgetState();
}

class _DatePromptWidgetState extends State<_DatePromptWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.redAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(
                    primary: Colors.redAccent,
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

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
              const SizedBox(width: 8),
              Text(
                'Set Final Deadline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
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
          const SizedBox(height: 12),
          _WeeklyDateSlider(
            selectedDate: _selectedDate,
            onDateSelected: (date) => setState(() => _selectedDate = date),
            selectedTime: _selectedTime,
            onTimeTap: () => _selectTime(context),
            actions: [
              TextButton(
                onPressed: () => widget.onConfirmed(null, null),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedDate == null
                    ? null
                    : () => widget.onConfirmed(_selectedDate, _selectedTime),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(60, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Set',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

Color _getMonthColor(int month) {
  switch (month) {
    case 1:
      return Colors.blueAccent;
    case 2:
      return Colors.pinkAccent;
    case 3:
      return Colors.lightGreenAccent;
    case 4:
      return Colors.cyanAccent;
    case 5:
      return Colors.tealAccent;
    case 6:
      return Colors.amberAccent;
    case 7:
      return Colors.orangeAccent;
    case 8:
      return Colors.redAccent;
    case 9:
      return Colors.deepOrangeAccent;
    case 10:
      return Colors.deepPurpleAccent;
    case 11:
      return Colors.indigoAccent;
    case 12:
      return Colors.blueGrey;
    default:
      return Colors.white70;
  }
}

class _WeeklyDateSlider extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final TimeOfDay? selectedTime;
  final VoidCallback onTimeTap;
  final List<Widget> actions;

  const _WeeklyDateSlider({
    this.selectedDate,
    required this.onDateSelected,
    this.selectedTime,
    required this.onTimeTap,
    required this.actions,
  });

  @override
  State<_WeeklyDateSlider> createState() => _WeeklyDateSliderState();
}

class _WeeklyDateSliderState extends State<_WeeklyDateSlider> {
  late PageController _pageController;
  late int _currentPage;
  final DateTime _baseSunday = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  // Jump UI state
  bool _isJumpUIOpen = false;
  int _selectedJumpMonth = DateTime.now().month;
  int _selectedJumpYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _currentPage =
        1000; // Start in the "middle" for infinite-ish horizontal scroll
    _pageController = PageController(initialPage: _currentPage);
  }

  void _jumpToDate(int month, int year) {
    final targetDate = DateTime(year, month, 1);
    final targetSunday = targetDate.subtract(
      Duration(days: targetDate.weekday % 7),
    );
    final daysDiff = targetSunday.difference(_baseSunday).inDays;
    final weeksDiff = (daysDiff / 7).floor();
    final pageOffset = (weeksDiff / 3).floor();

    setState(() {
      _isJumpUIOpen = false;
    });

    _pageController.animateToPage(
      1000 + pageOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    const weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weeksOffset = (_currentPage - 1000) * 3;
    final firstDay = _baseSunday.add(Duration(days: weeksOffset * 7));
    final lastDay = firstDay.add(const Duration(days: 20));
    final dateRangeStr =
        '${DateFormat('MMM d').format(firstDay)} - ${DateFormat('MMM d').format(lastDay)}';

    return Stack(
      children: [
        Column(
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
              height: 240,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, pageIndex) {
                  final weeksFromBase = (pageIndex - 1000) * 3;
                  final pageStartDate = _baseSunday.add(
                    Duration(days: weeksFromBase * 7),
                  );

                  return Column(
                    children: List.generate(3, (rowIndex) {
                      return Expanded(
                        child: Row(
                          children: List.generate(7, (colIndex) {
                            final dayIndex = rowIndex * 7 + colIndex;
                            final day = pageStartDate.add(
                              Duration(days: dayIndex),
                            );
                            final isPast =
                                day.isBefore(today) &&
                                !day.isAtSameMomentAs(today);
                            final isToday = day.isAtSameMomentAs(today);
                            final isEven = dayIndex % 2 == 0;
                            final isSelected =
                                widget.selectedDate != null &&
                                day.year == widget.selectedDate!.year &&
                                day.month == widget.selectedDate!.month &&
                                day.day == widget.selectedDate!.day;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: _DateTile(
                                  date: day,
                                  isPast: isPast,
                                  isToday: isToday,
                                  isSelected: isSelected,
                                  isEven: isEven,
                                  monthColor: _getMonthColor(day.month),
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
                  Material(
                    color: isDark
                        ? Colors.white.withAlpha(25)
                        : Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => setState(() => _isJumpUIOpen = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateRangeStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(width: 8),
                  // Time Picker Trigger
                  Material(
                    color: isDark
                        ? Colors.white.withAlpha(25)
                        : Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: widget.onTimeTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: widget.selectedTime != null
                                  ? Colors.redAccent
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.selectedTime != null
                                  ? widget.selectedTime!.format(context)
                                  : 'Add Time',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.selectedTime != null
                                    ? Colors.redAccent
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.95, 0.95)),
                  const Spacer(),
                  ...widget.actions,
                ],
              ),
            ),
          ],
        ),
        if (_isJumpUIOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isJumpUIOpen = false),
              child:
                  Container(
                        decoration: BoxDecoration(
                          color:
                              (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  .withAlpha(240),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 1.5,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                          ),
                                      itemCount: 12,
                                      itemBuilder: (context, index) {
                                        final isSelected =
                                            _selectedJumpMonth == (index + 1);
                                        final mColor = _getMonthColor(
                                          index + 1,
                                        );
                                        return InkWell(
                                              onTap: () => setState(
                                                () => _selectedJumpMonth =
                                                    index + 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? mColor.withAlpha(40)
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? mColor
                                                        : (isDark
                                                              ? Colors.white
                                                                    .withAlpha(
                                                                      26,
                                                                    )
                                                              : Colors.black
                                                                    .withAlpha(
                                                                      15,
                                                                    )),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    DateFormat('MMM').format(
                                                      DateTime(2024, index + 1),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? mColor
                                                          : (isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                      .black87),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(delay: (index * 20).ms)
                                            .scale(
                                              begin: const Offset(0.9, 0.9),
                                            );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 60,
                                    child: ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      perspective: 0.005,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: (index) {
                                        setState(
                                          () => _selectedJumpYear =
                                              DateTime.now().year + index,
                                        );
                                      },
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              final year =
                                                  DateTime.now().year + index;
                                              final isSelected =
                                                  _selectedJumpYear == year;
                                              return Center(
                                                child: Text(
                                                  year.toString(),
                                                  style: TextStyle(
                                                    fontSize: isSelected
                                                        ? 18
                                                        : 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.redAccent
                                                        : (isDark
                                                              ? Colors.white24
                                                              : Colors.black26),
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: 100,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isJumpUIOpen = false),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _jumpToDate(
                                        _selectedJumpMonth,
                                        _selectedJumpYear,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                      child: const Text('Jump'),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
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
  final bool isSelected;
  final bool isEven;
  final Color monthColor;
  final VoidCallback? onTap;

  const _DateTile({
    required this.date,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.isEven,
    required this.monthColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthStr = DateFormat('MMM').format(date).toUpperCase();
    final dayNum = date.day.toString();

    if (onTap != null) {
      Widget animatedContent = Column(
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
                  : (isToday || isSelected
                        ? Colors.white
                        : monthColor.withAlpha(180)),
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
                  : (isToday || isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      );

      return Container(
        decoration: BoxDecoration(
          color: isSelected
              ? monthColor
              : (isToday
                    ? (isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(10))
                    : (isPast
                          ? Colors.transparent
                          : (isDark
                                ? (isEven
                                      ? Colors.white.withAlpha(8)
                                      : Colors.white.withAlpha(3))
                                : (isEven
                                      ? Colors.black.withAlpha(8)
                                      : Colors.black.withAlpha(3))))),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? Colors.redAccent
                : (isSelected
                      ? monthColor
                      : (isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(10))),
            width: isToday || isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: monthColor.withAlpha(100),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : (isToday
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withAlpha(40),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: animatedContent,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
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
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          Text(
            dayNum,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
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
