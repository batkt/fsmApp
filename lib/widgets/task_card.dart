import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({super.key, required this.task, required this.statusColor,
      required this.statusLabel, required this.onStart,
      required this.onFinish, required this.onAttachPhoto,
      required this.onChat, required this.onTap});
  final CleaningTask task;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onStart, onFinish, onAttachPhoto, onChat, onTap;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  String _time() {
    String f(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
    return '${f(widget.task.startTime)} - ${f(widget.task.endTime)}';
  }

  Color _prioColor(TaskPriority p, AppColorScheme c) {
    switch (p) {
      case TaskPriority.high: return c.destructive;
      case TaskPriority.medium: return c.warningOrange;
      case TaskPriority.low: return c.success;
    }
  }

  IconData _prioIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Icons.keyboard_double_arrow_up;
      case TaskPriority.medium: return Icons.remove;
      case TaskPriority.low: return Icons.keyboard_arrow_down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = widget.task;
    final done = t.status == TaskStatus.completed;
    final prog = t.status == TaskStatus.inProgress;
    final pc = _prioColor(t.priority, c);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: prog
              ? c.info.withOpacity(0.3) : c.border),
        ),
        child: Column(children: [
          // ── Main row ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Icon
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: c.brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.cleaning_services_rounded,
                      color: c.brandGreen)),
                const SizedBox(width: 12),
                // Title + location
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(child: Text(t.title,
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: c.primary))),
                    // Priority indicator
                    Icon(_prioIcon(t.priority), size: 18, color: pc),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.place_outlined, size: 14,
                        color: c.mutedForeground),
                    const SizedBox(width: 3),
                    Expanded(child: Text(t.location,
                        style: TextStyle(fontSize: 14,
                            color: c.mutedForeground),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.schedule, size: 14,
                        color: c.mutedForeground),
                    const SizedBox(width: 3),
                    Text(_time(), style: TextStyle(fontSize: 14,
                        color: c.mutedForeground)),
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined, size: 14,
                        color: c.mutedForeground),
                    const SizedBox(width: 3),
                    Text('${t.estimatedMinutes} мин',
                        style: TextStyle(fontSize: 14,
                            color: c.mutedForeground)),
                  ]),
                ])),
              ]),

              const SizedBox(height: 10),

              // ── Status + subtask progress + expand ──
              Row(children: [
                // Status badge
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    borderRadius: BorderRadius.circular(999)),
                  child: Text(widget.statusLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                // Photo indicator (always visible)
                Icon(Icons.camera_alt_rounded, size: 16,
                    color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                        ? c.brandGreen : c.mutedForeground.withOpacity(0.4)),
                const SizedBox(width: 3),
                Text('${t.photoPaths.isNotEmpty ? t.photoPaths.length : t.photoCount}', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                        ? c.brandGreen : c.mutedForeground.withOpacity(0.4))),
                const SizedBox(width: 8),
                // Subtask progress
                if (t.subtasks.isNotEmpty) ...[
                  Icon(Icons.checklist_rounded, size: 16,
                      color: c.mutedForeground),
                  const SizedBox(width: 3),
                  Text('${t.subtasksDone}/${t.subtasks.length}',
                      style: TextStyle(fontSize: 15,
                          color: c.mutedForeground)),
                ],
                const Spacer(),
                // Quick chat button (always active)
                GestureDetector(
                  onTap: widget.onChat,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble_rounded, size: 18, color: c.brandGreen),
                  ),
                ),
                const SizedBox(width: 8),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.expand_more_rounded,
                          color: c.mutedForeground, size: 24),
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Expandable Section ──
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.muted.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16))),
              child: Column(children: [
                Divider(color: c.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Subtask preview
                    if (t.subtasks.isNotEmpty) ...[
                      Row(children: [
                        Text('Дэд даалгавар', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: c.primary)),
                        const Spacer(),
                        SizedBox(width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: t.subtaskProgress,
                              minHeight: 4,
                              backgroundColor: c.border,
                              valueColor: AlwaysStoppedAnimation(
                                  c.brandGreen)))),
                      ]),
                      const SizedBox(height: 8),
                      ...t.subtasks.take(4).map((st) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Icon(st.isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                              size: 16,
                              color: st.isDone
                                  ? c.success : c.mutedForeground),
                          const SizedBox(width: 6),
                          Text(st.title, style: TextStyle(
                              fontSize: 14,
                              color: st.isDone
                                  ? c.mutedForeground : c.primary,
                              decoration: st.isDone
                                  ? TextDecoration.lineThrough
                                  : null)),
                        ]),
                      )),
                      if (t.subtasks.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                              '+${t.subtasks.length - 4} бусад...',
                              style: TextStyle(fontSize: 15,
                                  color: c.brandGreen)),
                        ),
                    ],
                    // Notes preview
                    if (t.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 14, color: c.chart4),
                        const SizedBox(width: 4),
                        Expanded(child: Text(t.notes,
                            style: TextStyle(fontSize: 14,
                                color: c.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    // Action buttons
                    // Action buttons
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: done ? null : widget.onAttachPhoto,
                        icon: Icon(t.hasPhoto
                            ? Icons.verified_rounded
                            : Icons.camera_alt_outlined, size: 16),
                        label: Text(t.hasPhoto
                            ? 'Баталгаажсан' : 'Зураг',
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          foregroundColor: t.hasPhoto
                              ? c.success : c.brandGreen,
                          side: BorderSide(color: t.hasPhoto
                              ? c.success : c.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      )),
                      const SizedBox(width: 8),
                      if (!done) ...[
                        if (!prog)
                          Expanded(child: ElevatedButton.icon(
                            onPressed: widget.onStart,
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 16),
                            label: const Text('Эхлэх',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.info,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              elevation: 0),
                          )),
                        if (prog)
                          Expanded(child: ElevatedButton.icon(
                            onPressed: widget.onFinish,
                            icon: const Icon(Icons.check_rounded,
                                size: 16),
                            label: const Text('Дуусгах',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.brandGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              elevation: 0),
                          )),
                      ],
                    ]),
                  ]),
                ),
              ]),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ]),
      ),
    );
  }
}
