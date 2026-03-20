import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../services/holiday_service.dart';

class FullCalendar extends StatefulWidget {
  const FullCalendar({
    super.key,
    required this.selectedDay,
    required this.onSelected,
    required this.tasks,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;
  final List<CleaningTask> tasks;

  @override
  State<FullCalendar> createState() => _FullCalendarState();
}

class _FullCalendarState extends State<FullCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  bool _expanded = false;
  int _weekOffset = 0; // 0 = selected day's week, -1 = prev, +1 = next
  double _dragOffset = 0.0; // For visual feedback during drag
  double _totalDragDistance = 0.0; // Track total drag distance
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _prevMonth() => setState(
    () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1),
  );

  void _nextMonth() => setState(
    () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1),
  );

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CleaningTask> _tasksForDay(DateTime day) {
    final d = stripTime(day);
    return widget.tasks.where((t) {
      // 1. Check if it's the specific single-day date
      if (_same(t.date, d)) return true;

      // 2. Check if it's a multi-day or looping task
      if (t.isLoop || t.isDay) {
        if (t.ekhlekhOgnoo == null) return false;
        final start = stripTime(t.ekhlekhOgnoo!);
        
        // If it has an end date, check range. Otherwise, from start onwards?
        // User said: "if it not loop but day it should also show in from start do end"
        // Also: "it shows everyday until date is duusakh"
        if (t.duusakhOgnoo != null) {
          final end = stripTime(t.duusakhOgnoo!);
          return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
                 (d.isAtSameMomentAs(end) || d.isBefore(end));
        } else {
          // No end date - assume it's ongoing from start
          return d.isAtSameMomentAs(start) || d.isAfter(start);
        }
      }

      return false;
    }).toList()
      ..sort((a, b) {
        final am = a.startTime.hour * 60 + a.startTime.minute;
        final bm = b.startTime.hour * 60 + b.startTime.minute;
        return am.compareTo(bm);
      });
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending:
        return c.warningOrange;
      case TaskStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TaskStatus.completed:
        return c.brandGreen;
      case TaskStatus.overdue:
        return c.destructive;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Хүлээгдэж буй';
      case TaskStatus.inProgress:
        return 'Явагдаж буй';
      case TaskStatus.completed:
        return 'Дууссан';
      case TaskStatus.overdue:
        return 'Хугацаа хэтэрсэн';
    }
  }

  static const _dayNames = [
    '',
    'Даваа',
    'Мягмар',
    'Лхагва',
    'Пүрэв',
    'Баасан',
    'Бямба',
    'Ням',
  ];

  void _showDayModal(BuildContext context, DateTime date) {
    final c = context.colors;
    final dayTasks = _tasksForDay(date);
    final dayName = _dayNames[date.weekday];
    final monthName = _monthNames[date.month];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.brandGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayName, $monthName сар',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Builder(
                          builder: (context) {
                            final holiday = HolidayService.getHoliday(date);
                            if (holiday != null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  holiday.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.blueAccent,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        Text(
                          dayTasks.isEmpty
                              ? 'Даалгавар байхгүй'
                              : '${dayTasks.length} даалгавар',
                          style: TextStyle(
                            fontSize: 14,
                            color: c.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            // Task list
            if (dayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 48, color: c.border),
                    const SizedBox(height: 8),
                    Text(
                      'Энэ өдөр даалгавар байхгүй',
                      style: TextStyle(color: c.mutedForeground, fontSize: 15),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: dayTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t = dayTasks[i];
                    final sc = _statusColor(t.status, c);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.muted,
                        borderRadius: BorderRadius.circular(14),
                        border: t.status == TaskStatus.inProgress
                            ? Border.all(color: sc.withOpacity(0.4), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Time column
                          Column(
                            children: [
                              Text(
                                t.timeRange.split(' - ')[0],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: c.primary,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 16,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                color: sc.withOpacity(0.3),
                              ),
                              Text(
                                t.timeRange.split(' - ').last,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Task info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 14,
                                      color: c.mutedForeground,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        t.location,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: c.mutedForeground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status chip
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: sc,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(t.status),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Get the week (Mon-Sun) with offset
  List<DateTime> _currentWeekDays() {
    final sel = widget.selectedDay;
    final monday = sel.subtract(Duration(days: sel.weekday - 1));
    final offsetMonday = monday.add(Duration(days: _weekOffset * 7));
    return List.generate(7, (i) => offsetMonday.add(Duration(days: i)));
  }

  static const _monthNames = [
    '',
    'Нэгдүгээр',
    'Хоёрдугаар',
    'Гуравдугаар',
    'Дөрөвдүгээр',
    'Тавдугаар',
    'Зургадугаар',
    'Долоодугаар',
    'Наймдугаар',
    'Есдүгээр',
    'Аравдугаар',
    'Арван нэгдүгээр',
    'Арван хоёрдугаар',
  ];

  static const _weekHeaders = ['Дав', 'Мяг', 'Лха', 'Пүр', 'Баа', 'Бям', 'Ням'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header with month nav + expand toggle ──
          Row(
            children: [
              if (_expanded)
                IconButton(
                  onPressed: _prevMonth,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: c.primary,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMonth = DateTime(today.year, today.month);
                      _weekOffset = 0;
                    });
                    widget.onSelected(stripTime(today));
                  },
                  child: Column(
                    children: [
                      Builder(
                        builder: (_) {
                          final displayDate = _expanded
                              ? _currentMonth
                              : _currentWeekDays()[3]; // mid-week for month label
                          return Text(
                            '${_monthNames[displayDate.month]} сар, ${displayDate.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: c.primary,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              // Expand/Collapse button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                    if (_expanded) {
                      _currentMonth = DateTime(
                        widget.selectedDay.year,
                        widget.selectedDay.month,
                      );
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: c.mutedForeground,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Content: collapsed week strip OR expanded month grid ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                HapticFeedback.lightImpact();
                setState(() {
                  _isDragging = true;
                  _dragOffset = 0.0;
                  _totalDragDistance = 0.0;
                });
              },
              onHorizontalDragUpdate: (details) {
                final delta = details.primaryDelta ?? 0.0;
                setState(() {
                  // Accumulate drag offset - no resistance for immediate feedback
                  _dragOffset = (_dragOffset + delta).clamp(-200.0, 200.0);
                  _totalDragDistance += delta;
                });
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0.0;
                final distance = _totalDragDistance.abs();

                // Much lower thresholds for easier triggering
                // Swipe if moved more than 25px OR velocity > 100px/s
                final shouldSwipe = distance > 25 || velocity.abs() > 100;

                if (shouldSwipe) {
                  HapticFeedback.mediumImpact();
                  if (_totalDragDistance < 0 || velocity < 0) {
                    // Swipe left - next week
                    setState(() {
                      _weekOffset++;
                      _isDragging = false;
                      _dragOffset = 0.0;
                      _totalDragDistance = 0.0;
                    });
                  } else if (_totalDragDistance > 0 || velocity > 0) {
                    // Swipe right - previous week
                    setState(() {
                      _weekOffset--;
                      _isDragging = false;
                      _dragOffset = 0.0;
                      _totalDragDistance = 0.0;
                    });
                  } else {
                    setState(() {
                      _isDragging = false;
                      _dragOffset = 0.0;
                      _totalDragDistance = 0.0;
                    });
                  }
                } else {
                  // Snap back if not enough swipe
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isDragging = false;
                    _dragOffset = 0.0;
                    _totalDragDistance = 0.0;
                  });
                }
              },
              onHorizontalDragCancel: () {
                setState(() {
                  _isDragging = false;
                  _dragOffset = 0.0;
                  _totalDragDistance = 0.0;
                });
              },
              child: Stack(
                children: [
                  // Background week strip (for peek effect) - shows next/prev week
                  if (_isDragging && _dragOffset.abs() > 15)
                    Positioned.fill(
                      child: Opacity(
                        opacity:
                            (0.2 + (_dragOffset.abs() / 200.0).clamp(0.0, 0.3)),
                        child: Transform.translate(
                          offset: Offset(
                            _dragOffset < 0
                                ? MediaQuery.of(context).size.width * 0.8 +
                                      _dragOffset
                                : -MediaQuery.of(context).size.width * 0.8 +
                                      _dragOffset,
                            0,
                          ),
                          child: _buildWeekStrip(
                            c,
                            today,
                            key: ValueKey(
                              _weekOffset + (_dragOffset < 0 ? 1 : -1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Main week strip with drag feedback
                  AnimatedContainer(
                    duration: _isDragging
                        ? const Duration(milliseconds: 0)
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(_dragOffset, 0, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: Offset(
                                  _dragOffset < 0 ? -0.3 : 0.3,
                                  0.0,
                                ),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Opacity(
                        opacity: _isDragging
                            ? (1.0 -
                                  (_dragOffset.abs() / 200.0).clamp(0.0, 0.4))
                            : 1.0,
                        child: _buildWeekStrip(
                          c,
                          today,
                          key: ValueKey(_weekOffset),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: _buildMonthGrid(c, today),
          ),

          // ── Swipe tip (only when collapsed) ──
          if (!_expanded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  size: 16,
                  color: c.mutedForeground.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Долоо хоног шударна уу',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.mutedForeground.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: c.mutedForeground.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   COLLAPSED: Week Strip (Mon to Sun)
  // ═══════════════════════════════════════════════
  Widget _buildWeekStrip(AppColorScheme c, DateTime today, {Key? key}) {
    final weekDays = _currentWeekDays();
    return Row(
      key: key,
      children: List.generate(7, (i) {
        final day = weekDays[i];
        final isToday = _same(day, today);
        final isSelected = _same(day, widget.selectedDay);
        final dayTasks = _tasksForDay(day);

        return Expanded(
          child: GestureDetector(
            onTap: () {
              widget.onSelected(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 76,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? c.brandGreen
                    : isToday
                    ? c.brandGreen.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(
                        color: c.brandGreen.withOpacity(0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekHeaders[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : c.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : c.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Task dots — always same height
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (HolidayService.getHoliday(day) != null)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : c.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ...dayTasks
                            .take(isSelected ? 3 : 2)
                            .map(
                              (t) => Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : _statusColor(t.status, c),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  //   EXPANDED: Full Month Grid
  // ═══════════════════════════════════════════════
  Widget _buildMonthGrid(AppColorScheme c, DateTime today) {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startWeekday = firstOfMonth.weekday;
    final daysInMonth = lastOfMonth.day;
    final leadingDays = startWeekday - 1;
    final prevMonthLast = DateTime(_currentMonth.year, _currentMonth.month, 0);
    final rows = ((leadingDays + daysInMonth + 6) / 7).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Weekday headers
        Row(
          children: _weekHeaders
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: d == 'Бям' || d == 'Ням'
                            ? c.destructive.withOpacity(0.7)
                            : c.mutedForeground,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),

        // Day cells
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - leadingDays + 1;

                if (dayNum < 1 || dayNum > daysInMonth) {
                  final otherDay = dayNum < 1
                      ? prevMonthLast.day + dayNum
                      : dayNum - daysInMonth;
                  return Expanded(
                    child: Container(
                      height: 46,
                      margin: const EdgeInsets.all(1),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$otherDay',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.mutedForeground.withOpacity(0.3),
                        ),
                      ),
                    ),
                  );
                }

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNum,
                );
                final isToday = _same(date, today);
                final isSelected = _same(date, widget.selectedDay);
                final dayTasks = _tasksForDay(date);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onSelected(date);
                      _showDayModal(context, date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 46,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.brandGreen
                            : isToday
                            ? c.brandGreen.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: c.brandGreen.withOpacity(0.4),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (col >= 5
                                        ? c.destructive.withOpacity(0.7)
                                        : c.primary),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final holiday = HolidayService.getHoliday(date);
                              final hasTasks = dayTasks.isNotEmpty;
                              if (holiday == null && !hasTasks)
                                return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (holiday != null)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 0.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : c.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ...dayTasks
                                        .take(3)
                                        .map(
                                          (t) => Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 0.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : _statusColor(t.status, c),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
