import 'package:flutter/material.dart';
import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TaskListSection extends StatelessWidget {
  final bool isLoading;
  final List<CleaningTask> tasks;
  final Color Function(TaskStatus) statusColor;
  final String Function(TaskStatus) statusLabel;
  final void Function(CleaningTask) onStart;
  final void Function(CleaningTask) onFinish;
  final void Function(CleaningTask) onAttachPhoto;
  final void Function(CleaningTask) onTap;
  final void Function(CleaningTask) onChat;

  const TaskListSection({
    super.key,
    required this.isLoading,
    required this.tasks,
    required this.statusColor,
    required this.statusLabel,
    required this.onStart,
    required this.onFinish,
    required this.onAttachPhoto,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: c.brandGreen,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available, size: 48, color: c.border),
              const SizedBox(height: 8),
              Text(
                'Даалгавар олдсонгүй.',
                style: TextStyle(color: c.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${tasks.length} даалгавар',
            style: TextStyle(fontSize: 13, color: c.mutedForeground),
          ),
        ),
        ...tasks.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: t,
              statusColor: statusColor(t.status),
              statusLabel: statusLabel(t.status),
              onStart: () => onStart(t),
              onFinish: () => onFinish(t),
              onAttachPhoto: () => onAttachPhoto(t),
              onTap: () => onTap(t),
              onChat: () => onChat(t),
            ),
          ),
        ),
      ],
    );
  }
}
