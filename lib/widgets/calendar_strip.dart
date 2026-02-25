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

class _FullCalendarState extends State<FullCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

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
      case TaskStatus.pending:
        return c.warningOrange;
      case TaskStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TaskStatus.completed:
        return c.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();

    // Month header
    const monthNames = [
      '', 'Нэгдүгээр сар', 'Хоёрдугаар сар', 'Гуравдугаар сар',
      'Дөрөвдүгээр сар', 'Тавдугаар сар', 'Зургадугаар сар',
      'Долоодугаар сар', 'Наймдугаар сар', 'Есдүгээр сар',
      'Аравдугаар сар', 'Арван нэгдүгээр сар', 'Арван хоёрдугаар сар'
    ];

    // Build day grid
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // 1=Monday ... 7=Sunday
    final startWeekday = firstOfMonth.weekday; // 1-7
    final daysInMonth = lastOfMonth.day;

    // Cells before the 1st (from prev month)
    final prevMonthLast = DateTime(_currentMonth.year, _currentMonth.month, 0);
    final leadingDays = startWeekday - 1; // Mon=0, Tue=1, ... Sun=6

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Month navigation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left_rounded,
                    color: c.primary, size: 28),
              ),
              GestureDetector(
                onTap: () {
                  // Reset to current month
                  setState(() {
                    _currentMonth = DateTime(today.year, today.month);
                  });
                  widget.onSelected(stripTime(today));
                },
                child: Column(children: [
                  Text(
                    '${_currentMonth.year}',
                    style: TextStyle(
                        fontSize: 13, color: c.mutedForeground),
                  ),
                  Text(
                    monthNames[_currentMonth.month],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                ]),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right_rounded,
                    color: c.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Weekday headers ──
          Row(
            children: ['Дав', 'Мяг', 'Лха', 'Пүр', 'Баа', 'Бям', 'Ням']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: d == 'Бям' || d == 'Ням'
                                    ? c.destructive.withOpacity(0.7)
                                    : c.mutedForeground)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── Day grid ──
          ...List.generate(_rowCount(leadingDays, daysInMonth), (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingDays + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    // Empty / other month
                    final otherDay = dayNum < 1
                        ? prevMonthLast.day + dayNum
                        : dayNum - daysInMonth;
                    return Expanded(
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.all(1),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$otherDay',
                          style: TextStyle(
                              fontSize: 13,
                              color: c.mutedForeground.withOpacity(0.35)),
                        ),
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
                      onTap: () => widget.onSelected(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 52,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.brandGreen
                              : isToday
                                  ? c.brandGreen.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: c.brandGreen.withOpacity(0.4),
                                  width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Day number
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 15,
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
                            const SizedBox(height: 3),
                            // Task dots
                            if (dayTasks.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dayTasks
                                    .take(4)
                                    .map((t) => Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.8)
                                                : _statusColor(t.status, c),
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
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
      ),
    );
  }

  int _rowCount(int leading, int daysInMonth) {
    return ((leading + daysInMonth + 6) / 7).floor();
  }
}
