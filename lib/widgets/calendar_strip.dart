import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({super.key, required this.days,
      required this.selectedDay, required this.onSelected});
  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final sel = _same(day, selectedDay);
          return GestureDetector(
            onTap: () => onSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 60,
              decoration: BoxDecoration(
                color: sel ? c.brandGreen : c.muted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? c.brandGreen : c.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weekday(day.weekday),
                      style: TextStyle(fontSize: 12,
                          color: sel ? Colors.white : c.mutedForeground)),
                  const SizedBox(height: 4),
                  Text(day.day.toString().padLeft(2, '0'),
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : c.primary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekday(int w) {
    const m = {1:'Дав',2:'Мяг',3:'Лха',4:'Пүр',5:'Баа',6:'Бям',7:'Ням'};
    return m[w] ?? '';
  }
}
