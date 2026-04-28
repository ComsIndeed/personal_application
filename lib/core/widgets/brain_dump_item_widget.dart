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
  bool _isPromotionModalVisible = false;
  int _selectedCriticality = 3;
  int _selectedResistance = 3;
  DateTime? _selectedDueDate;

  @override
  void didUpdateWidget(BrainDumpItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _isPromotionModalVisible = false;
      _selectedCriticality = 3;
      _selectedResistance = 3;
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

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    : Colors.white.withAlpha(40))
              : ((_isHovered || isSelected)
                    ? Colors.black.withAlpha(40)
                    : Colors.black.withAlpha(30)),
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
            if (_isPromotionModalVisible && !widget.isPending)
              _PromotionModal(
                criticality: _selectedCriticality,
                resistance: _selectedResistance,
                dueDate: _selectedDueDate,
                onCriticalityChanged: (val) =>
                    setState(() => _selectedCriticality = val),
                onResistanceChanged: (val) =>
                    setState(() => _selectedResistance = val),
                onDueDateChanged: (val) =>
                    setState(() => _selectedDueDate = val),
                onConfirmed: () {
                  context.read<BrainDumpCubit>().promoteToTask(
                    widget.item,
                    TaskType.important,
                    dueDate: _selectedDueDate,
                    criticality: _selectedCriticality,
                    resistance: _selectedResistance,
                  );

                  context.read<AppTabController<AppTabId>>().animateToId(
                    AppTabId.sprints,
                  );
                },
                onCancel: () {
                  setState(() {
                    _isPromotionModalVisible = false;
                  });
                },
              ),
          ],
        ),
      ),
    );

    final hoverOverlay =
        (_isHovered && !widget.isPending && !_isPromotionModalVisible)
        ? Positioned(
            top: 20,
            right: 28,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(40)
                      : Colors.black.withAlpha(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isPromotionModalVisible = true;
                      });
                    },
                    icon: const Icon(Icons.add_task_rounded, size: 20),
                    color: Colors.redAccent,
                    tooltip: 'Promote',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(10),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<BrainDumpCubit>().deleteItem(widget.item.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: isDark ? Colors.white60 : Colors.black54,
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

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
          child: Stack(
            children: [
              widget.isPending
                  ? card.animate().shimmer(
                      duration: 1.5.seconds,
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withAlpha(10),
                    )
                  : card,
              hoverOverlay,
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.8, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.item.assetIds.isEmpty ? 200 : 80,
                ),
                child: Text(
                  widget.item.textContent!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
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

class _PromotionModal extends StatelessWidget {
  final int criticality;
  final int resistance;
  final DateTime? dueDate;
  final ValueChanged<int> onCriticalityChanged;
  final ValueChanged<int> onResistanceChanged;
  final ValueChanged<DateTime?> onDueDateChanged;
  final VoidCallback onConfirmed;
  final VoidCallback onCancel;

  const _PromotionModal({
    required this.criticality,
    required this.resistance,
    this.dueDate,
    required this.onCriticalityChanged,
    required this.onResistanceChanged,
    required this.onDueDateChanged,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(20),
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
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Colors.redAccent.withAlpha(180),
              ),
              const SizedBox(width: 8),
              Text(
                'UPGRADE TO TASK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Criticality Selector
          _ParameterSelectionRow(
            label: 'CRITICALITY',
            value: criticality,
            onChanged: onCriticalityChanged,
            lowLabel: 'Minor',
            highLabel: 'Vital',
            colorScale: [
              Colors.greenAccent,
              Colors.lightGreenAccent,
              Colors.yellowAccent,
              Colors.orangeAccent,
              Colors.redAccent,
            ],
          ),

          const SizedBox(height: 24),

          // Resistance Selector
          _ParameterSelectionRow(
            label: 'RESISTANCE',
            value: resistance,
            onChanged: onResistanceChanged,
            lowLabel: 'Flow',
            highLabel: 'Friction',
            colorScale: [
              Colors.greenAccent,
              Colors.lightGreenAccent,
              Colors.yellowAccent,
              Colors.orangeAccent,
              Colors.redAccent,
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'DEADLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          _WeeklyDateSlider(
            selectedDate: dueDate,
            onDateSelected: (date) {
              final currentDueDate = dueDate;
              if (currentDueDate != null &&
                  date.year == currentDueDate.year &&
                  date.month == currentDueDate.month &&
                  date.day == currentDueDate.day) {
                onDueDateChanged(null);
              } else {
                onDueDateChanged(date);
              }
            },
            // Reusing existing components, time selection omitted for brevity in first pass
            // but can be added back if needed by adding a time field to _PromotionModal
            selectedTime: null,
            onTimeTap: () {},
            actions: [
              IconButton(
                onPressed: onConfirmed,
                icon: const Icon(Icons.check_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Set as Task',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ParameterSelectionRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String lowLabel;
  final String highLabel;
  final List<Color> colorScale;

  const _ParameterSelectionRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.lowLabel,
    required this.highLabel,
    required this.colorScale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = value == level;
            final color = colorScale[index];

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withAlpha(isDark ? 80 : 100)
                        : color.withAlpha(isDark ? 20 : 30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : color.withAlpha(isDark ? 30 : 40),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: isSelected
                                ? color
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Text(
                            lowLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                        ),
                      if (index == 4)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Text(
                            highLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
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
                  ),
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
