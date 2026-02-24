import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.tasksForDay});
  final List<CleaningTask> tasksForDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = tasksForDay.length;
    final done = tasksForDay.where((t) =>
        t.status == TaskStatus.completed).length;
    final prog = tasksForDay.where((t) =>
        t.status == TaskStatus.inProgress).length;

    return Row(children: [
      _Chip(label: 'Нийт', value: '$total', color: c.chart3),
      const SizedBox(width: 8),
      _Chip(label: 'Явагдаж буй', value: '$prog', color: c.info),
      const SizedBox(width: 8),
      _Chip(label: 'Дууссан', value: '$done', color: c.success),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value,
      required this.color});
  final String label; final String value; final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold,
            color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12,
            color: color.withOpacity(0.8))),
      ]),
    );
  }
}
