import 'package:flutter/material.dart';
import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
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
          padding: context.rSymmetricPadding(vertical: 40),
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
          padding: context.rSymmetricPadding(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.rSpacing(84),
                height: context.rSpacing(84),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF6B003).withValues(alpha: 0.18),
                      const Color(0xFFE67E00).withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Icon(Icons.event_available_rounded, size: context.rIconSize(38), color: c.brandGreen),
              ),
              context.rHeight(14),
              Text(
                'Энэ өдөр даалгавар алга',
                style: TextStyle(color: c.primary, fontSize: context.rFontSize(15), fontWeight: FontWeight.w500),
              ),
              context.rHeight(4),
              Text(
                'Өөр өдөр сонгох эсвэл доош татаж шинэчилнэ үү',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.mutedForeground, fontSize: context.rFontSize(13)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...tasks.map(
          (t) => Padding(
            padding: context.rPadding(bottom: 12),
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
