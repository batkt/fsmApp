import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _prevMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));

  void _nextMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CleaningTask> _tasksForDay(DateTime day) {
    return widget.tasks
        .where((t) => _same(t.date, day))
        .toList()
      ..sort((a, b) {
        final am = a.startTime.hour * 60 + a.startTime.minute;
        final bm = b.startTime.hour * 60 + b.startTime.minute;
        return am.compareTo(bm);
      });
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending: return c.warningOrange;
      case TaskStatus.inProgress: return const Color(0xFF3B82F6);
      case TaskStatus.completed: return c.brandGreen;
      case TaskStatus.overdue: return c.destructive;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return 'Хүлээгдэж буй';
      case TaskStatus.inProgress: return 'Явагдаж буй';
      case TaskStatus.completed: return 'Дууссан';
      case TaskStatus.overdue: return 'Хугацаа хэтэрсэн';
    }
  }

  static const _dayNames = [
    '', 'Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'
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
              width: 40, height: 4,
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
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: c.brandGreen)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$dayName, $monthName сар',
                          style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: c.primary)),
                      const SizedBox(height: 2),
                      Text(
                        dayTasks.isEmpty
                            ? 'Даалгавар байхгүй'
                            : '${dayTasks.length} даалгавар',
                        style: TextStyle(fontSize: 14,
                            color: c.mutedForeground),
                      ),
                    ],
                  )),
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
                child: Column(children: [
                  Icon(Icons.event_available, size: 48,
                      color: c.border),
                  const SizedBox(height: 8),
                  Text('Энэ өдөр даалгавар байхгүй',
                      style: TextStyle(color: c.mutedForeground,
                          fontSize: 15)),
                ]),
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
                                style: TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: c.primary),
                              ),
                              Container(
                                width: 2, height: 16,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                color: sc.withOpacity(0.3),
                              ),
                              Text(
                                t.timeRange.split(' - ').last,
                                style: TextStyle(fontSize: 13,
                                    color: c.mutedForeground),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Task info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    style: TextStyle(fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: c.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.place_outlined, size: 14,
                                      color: c.mutedForeground),
                                  const SizedBox(width: 3),
                                  Expanded(child: Text(t.location,
                                      style: TextStyle(fontSize: 13,
                                          color: c.mutedForeground),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status chip
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: sc,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(t.status),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
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

  /// Get the week (Mon-Sun) containing the selected day
  List<DateTime> _selectedWeekDays() {
    final sel = widget.selectedDay;
    final monday = sel.subtract(Duration(days: sel.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static const _monthNames = [
    '', 'Нэгдүгээр', 'Хоёрдугаар', 'Гуравдугаар',
    'Дөрөвдүгээр', 'Тавдугаар', 'Зургадугаар',
    'Долоодугаар', 'Наймдугаар', 'Есдүгээр',
    'Аравдугаар', 'Арван нэгдүгээр', 'Арван хоёрдугаар'
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
                  icon: Icon(Icons.chevron_left_rounded,
                      color: c.primary, size: 26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMonth = DateTime(today.year, today.month);
                    });
                    widget.onSelected(stripTime(today));
                  },
                  child: Column(children: [
                    Text(
                      '${_monthNames[_expanded ? _currentMonth.month : widget.selectedDay.month]} сар, ${_expanded ? _currentMonth.year : widget.selectedDay.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.primary,
                      ),
                    ),
                  ]),
                ),
              ),
              if (_expanded)
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right_rounded,
                      color: c.primary, size: 26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              // Expand/Collapse button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                    if (_expanded) {
                      _currentMonth = DateTime(
                          widget.selectedDay.year, widget.selectedDay.month);
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
                    color: c.mutedForeground, size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Content: collapsed week strip OR expanded month grid ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildWeekStrip(c, today),
            secondChild: _buildMonthGrid(c, today),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   COLLAPSED: Week Strip (Mon to Sun)
  // ═══════════════════════════════════════════════
  Widget _buildWeekStrip(AppColorScheme c, DateTime today) {
    final weekDays = _selectedWeekDays();
    return Row(
      children: List.generate(7, (i) {
        final day = weekDays[i];
        final isToday = _same(day, today);
        final isSelected = _same(day, widget.selectedDay);
        final dayTasks = _tasksForDay(day);

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? c.brandGreen
                    : isToday
                        ? c.brandGreen.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: c.brandGreen.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  // Task dots
                  if (dayTasks.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayTasks.take(3).map((t) => Container(
                        width: 5, height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : _statusColor(t.status, c),
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
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
    final lastOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
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
          children: _weekHeaders.map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: d == 'Бям' || d == 'Ням'
                        ? c.destructive.withOpacity(0.7)
                        : c.mutedForeground,
                  )),
            ),
          )).toList(),
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
                      child: Text('$otherDay',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.mutedForeground.withOpacity(0.3),
                          )),
                    ),
                  );
                }

                final date = DateTime(
                    _currentMonth.year, _currentMonth.month, dayNum);
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
                                width: 1.5)
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
                          if (dayTasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dayTasks.take(4).map((t) => Container(
                                  width: 5, height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : _statusColor(t.status, c),
                                    shape: BoxShape.circle,
                                  ),
                                )).toList(),
                              ),
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
