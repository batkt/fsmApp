import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

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
          borderRadius: BorderRadius.circular(context.rRadius(16)),
          boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: prog
              ? c.info.withOpacity(0.3) : c.border),
        ),
        child: Column(children: [
          // ── Main row ──
          Padding(
            padding: context.rPadding(all: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Icon
                Container(
                  width: context.rIconSize(44),
                  height: context.rIconSize(44),
                  decoration: BoxDecoration(
                    color: c.brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.rRadius(12))),
                  child: Icon(
                    Icons.cleaning_services_rounded,
                    color: c.brandGreen,
                    size: context.rIconSize(24),
                  )),
                context.rWidth(12),
                // Title + location
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(child: Text(t.title,
                        style: TextStyle(
                          fontSize: context.rFontSize(17),
                          fontWeight: FontWeight.w600,
                          color: c.primary))),
                    // Priority indicator
                    Icon(
                      _prioIcon(t.priority),
                      size: context.rIconSize(18),
                      color: pc,
                    ),
                  ]),
                  context.rHeight(4),
                  Row(children: [
                    Icon(
                      Icons.place_outlined,
                      size: context.rIconSize(14),
                      color: c.mutedForeground,
                    ),
                    context.rWidth(3),
                    Expanded(child: Text(t.location,
                        style: TextStyle(
                          fontSize: context.rFontSize(14),
                          color: c.mutedForeground),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  context.rHeight(4),
                  Row(children: [
                    Icon(
                      Icons.schedule,
                      size: context.rIconSize(14),
                      color: c.mutedForeground,
                    ),
                    context.rWidth(3),
                    Text(_time(), style: TextStyle(
                      fontSize: context.rFontSize(14),
                      color: c.mutedForeground)),
                    context.rWidth(10),
                    Icon(
                      Icons.timer_outlined,
                      size: context.rIconSize(14),
                      color: c.mutedForeground,
                    ),
                    context.rWidth(3),
                    Text('${t.estimatedMinutes} мин',
                        style: TextStyle(
                          fontSize: context.rFontSize(14),
                          color: c.mutedForeground)),
                  ]),
                ])),
              ]),

              context.rHeight(10),

              // ── Status + subtask progress + expand ──
              Row(children: [
                // Status badge
                Container(
                  width: context.rSpacing(120),
                  padding: context.rSymmetricPadding(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    borderRadius: BorderRadius.circular(999)),
                  child: Text(widget.statusLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.rFontSize(13),
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                ),
                context.rWidth(8),
                // Photo indicator (always visible)
                Icon(
                  Icons.camera_alt_rounded,
                  size: context.rIconSize(16),
                  color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                      ? c.brandGreen : c.mutedForeground.withOpacity(0.4)),
                context.rWidth(3),
                Text('${t.photoPaths.isNotEmpty ? t.photoPaths.length : t.photoCount}', style: TextStyle(
                    fontSize: context.rFontSize(13),
                    fontWeight: FontWeight.w600,
                    color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                        ? c.brandGreen : c.mutedForeground.withOpacity(0.4))),
                context.rWidth(8),
                // Subtask progress
                if (t.subtasks.isNotEmpty) ...[
                  Icon(
                    Icons.checklist_rounded,
                    size: context.rIconSize(16),
                    color: c.mutedForeground),
                  context.rWidth(3),
                  Text('${t.subtasksDone}/${t.subtasks.length}',
                      style: TextStyle(
                        fontSize: context.rFontSize(15),
                        color: c.mutedForeground)),
                ],
                const Spacer(),
                // Quick chat button (always active)
                GestureDetector(
                  onTap: widget.onChat,
                  child: Container(
                    padding: context.rPadding(all: 6),
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: context.rIconSize(18),
                      color: c.brandGreen),
                  ),
                ),
                context.rWidth(8),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: context.rPadding(all: 4),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: c.mutedForeground,
                        size: context.rIconSize(24)),
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
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(context.rRadius(16)))),
              child: Column(children: [
                Divider(color: c.border, height: 1),
                Padding(
                  padding: context.rPadding(all: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Subtask preview
                    if (t.subtasks.isNotEmpty) ...[
                      Row(children: [
                        Text('Дэд даалгавар', style: TextStyle(
                            fontSize: context.rFontSize(14),
                            fontWeight: FontWeight.w600,
                            color: c.primary)),
                        const Spacer(),
                        SizedBox(
                          width: context.rSpacing(60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.rRadius(3)),
                            child: LinearProgressIndicator(
                              value: t.subtaskProgress,
                              minHeight: context.rSpacing(4),
                              backgroundColor: c.border,
                              valueColor: AlwaysStoppedAnimation(
                                  c.brandGreen)))),
                      ]),
                      context.rHeight(8),
                      ...t.subtasks.take(4).map((st) => Padding(
                        padding: context.rPadding(bottom: 4),
                        child: Row(children: [
                          Icon(
                            st.isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: context.rIconSize(16),
                            color: st.isDone
                                ? c.success : c.mutedForeground),
                          context.rWidth(6),
                          Text(st.title, style: TextStyle(
                              fontSize: context.rFontSize(14),
                              color: st.isDone
                                  ? c.mutedForeground : c.primary,
                              decoration: st.isDone
                                  ? TextDecoration.lineThrough
                                  : null)),
                        ]),
                      )),
                      if (t.subtasks.length > 4)
                        Padding(
                          padding: context.rPadding(top: 2),
                          child: Text(
                              '+${t.subtasks.length - 4} бусад...',
                              style: TextStyle(
                                fontSize: context.rFontSize(15),
                                color: c.brandGreen)),
                        ),
                    ],
                    // Notes preview
                    if (t.notes.isNotEmpty) ...[
                      context.rHeight(8),
                      Row(children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: context.rIconSize(14),
                          color: c.chart4),
                        context.rWidth(4),
                        Expanded(child: Text(t.notes,
                            style: TextStyle(
                              fontSize: context.rFontSize(14),
                              color: c.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    context.rHeight(10),
                    // Action buttons
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: done ? null : widget.onAttachPhoto,
                        icon: Icon(
                          t.hasPhoto
                              ? Icons.verified_rounded
                              : Icons.camera_alt_outlined,
                          size: context.rIconSize(16)),
                        label: Text(t.hasPhoto
                            ? 'Баталгаажсан' : 'Зураг',
                            style: TextStyle(fontSize: context.rFontSize(12))),
                        style: OutlinedButton.styleFrom(
                          padding: context.rSymmetricPadding(vertical: 8),
                          foregroundColor: t.hasPhoto
                              ? c.success : c.brandGreen,
                          side: BorderSide(color: t.hasPhoto
                              ? c.success : c.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(context.rRadius(10)))),
                      )),
                      context.rWidth(8),
                      if (!done) ...[
                        if (!prog)
                          Expanded(child: ElevatedButton.icon(
                            onPressed: widget.onStart,
                            icon: Icon(
                              Icons.play_arrow_rounded,
                              size: context.rIconSize(16)),
                            label: Text('Эхлэх',
                                style: TextStyle(fontSize: context.rFontSize(12))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.info,
                              foregroundColor: Colors.white,
                              padding: context.rSymmetricPadding(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(context.rRadius(10))),
                              elevation: 0),
                          )),
                        if (prog)
                          Expanded(child: ElevatedButton.icon(
                            onPressed: widget.onFinish,
                            icon: Icon(
                              Icons.check_rounded,
                              size: context.rIconSize(16)),
                            label: Text('Дуусгах',
                                style: TextStyle(fontSize: context.rFontSize(12))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.brandGreen,
                              foregroundColor: Colors.white,
                              padding: context.rSymmetricPadding(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(context.rRadius(10))),
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
