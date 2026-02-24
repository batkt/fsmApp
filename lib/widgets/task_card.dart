import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.statusColor,
      required this.statusLabel, required this.onStart,
      required this.onFinish, required this.onAttachPhoto});
  final CleaningTask task;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onStart, onFinish, onAttachPhoto;

  String _time() {
    String f(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
    return '${f(task.startTime)} - ${f(task.endTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = task.status == TaskStatus.completed;
    final prog = task.status == TaskStatus.inProgress;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.cleaning_services_rounded,
                color: c.brandGreen)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: c.primary)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.place_outlined, size: 16,
                  color: c.mutedForeground),
              const SizedBox(width: 4),
              Expanded(child: Text(task.location,
                  style: TextStyle(fontSize: 12,
                      color: c.mutedForeground),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.schedule, size: 16,
                  color: c.mutedForeground),
              const SizedBox(width: 4),
              Text(_time(), style: TextStyle(fontSize: 12,
                  color: c.mutedForeground)),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.2))),
            child: Text(statusLabel, style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w500, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: done ? null : onAttachPhoto,
            icon: Icon(task.hasPhoto ? Icons.verified_rounded
                : Icons.camera_alt_outlined, size: 18),
            label: Text(task.hasPhoto ? 'Баталгаажсан' : 'Зураг авах'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              foregroundColor: task.hasPhoto ? c.success : c.brandGreen,
              side: BorderSide(color: task.hasPhoto
                  ? c.success : c.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          )),
          const SizedBox(width: 8),
          if (!done) ...[
            if (!prog) TextButton(onPressed: onStart,
                style: TextButton.styleFrom(foregroundColor: c.info),
                child: const Text('Эхлэх')),
            if (prog) ElevatedButton(onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0),
                child: const Text('Дуусгах')),
          ],
        ]),
      ]),
    );
  }
}
