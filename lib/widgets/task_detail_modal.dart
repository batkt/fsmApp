import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

class TaskDetailModal extends StatefulWidget {
  const TaskDetailModal({super.key, required this.task,
      required this.onStatusChange, required this.onSubtaskToggle,
      required this.onPhoto});
  final CleaningTask task;
  final VoidCallback onStatusChange;
  final void Function(int) onSubtaskToggle;
  final VoidCallback onPhoto;

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  CleaningTask get t => widget.task;

  Color _prioColor(TaskPriority p, AppColorScheme c) {
    switch (p) {
      case TaskPriority.high: return c.destructive;
      case TaskPriority.medium: return c.warningOrange;
      case TaskPriority.low: return c.success;
    }
  }

  String _prioLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 'Өндөр';
      case TaskPriority.medium: return 'Дунд';
      case TaskPriority.low: return 'Бага';
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return 'Хүлээгдэж буй';
      case TaskStatus.inProgress: return 'Явагдаж буй';
      case TaskStatus.completed: return 'Дууссан';
    }
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending: return c.warningOrange;
      case TaskStatus.inProgress: return c.info;
      case TaskStatus.completed: return c.success;
    }
  }

  String _fmt(TimeOfDay td) =>
      '${td.hour.toString().padLeft(2, '0')}:${td.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sc = _statusColor(t.status, c);
    final pc = _prioColor(t.priority, c);
    final done = t.status == TaskStatus.completed;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: c.border,
                borderRadius: BorderRadius.circular(2))),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                  color: c.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.cleaning_services_rounded,
                  color: c.brandGreen, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(t.title, style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: c.primary)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sc.withOpacity(0.2))),
                  child: Text(_statusLabel(t.status),
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: sc))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: pc.withOpacity(0.2))),
                  child: Text(_prioLabel(t.priority),
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: pc))),
              ]),
            ])),
          ]),
        ),

        const SizedBox(height: 16),

        // Scrollable body
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Info grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.muted,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _InfoRow(c: c, icon: Icons.place_outlined,
                    label: 'Байршил', value: t.location),
                const SizedBox(height: 10),
                _InfoRow(c: c, icon: Icons.layers_outlined,
                    label: 'Давхар', value: t.floor),
                const SizedBox(height: 10),
                _InfoRow(c: c, icon: Icons.schedule_outlined,
                    label: 'Цаг',
                    value: '${_fmt(t.startTime)} - ${_fmt(t.endTime)}'),
                const SizedBox(height: 10),
                _InfoRow(c: c, icon: Icons.timer_outlined,
                    label: 'Тооцоолсон', value: '${t.estimatedMinutes} мин'),
                const SizedBox(height: 10),
                _InfoRow(c: c, icon: Icons.person_outline,
                    label: 'Удирдагч', value: t.supervisor),
              ]),
            ),

            // Notes
            if (t.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('📝 Тэмдэглэл', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600, color: c.primary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.chart4.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: c.chart4.withOpacity(0.15))),
                child: Text(t.notes, style: TextStyle(fontSize: 15,
                    color: c.primary, height: 1.4)),
              ),
            ],

            // Subtasks
            if (t.subtasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: [
                Text('☑ Дэд даалгавар', style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: c.primary)),
                const Spacer(),
                Text('${t.subtasksDone}/${t.subtasks.length}',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.brandGreen)),
              ]),
              const SizedBox(height: 8),
              // progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t.subtaskProgress,
                  minHeight: 6,
                  backgroundColor: c.muted,
                  valueColor: AlwaysStoppedAnimation(c.brandGreen))),
              const SizedBox(height: 12),
              ...List.generate(t.subtasks.length, (i) {
                final st = t.subtasks[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: done ? null : () {
                      setState(() => st.isDone = !st.isDone);
                      widget.onSubtaskToggle(i);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: st.isDone
                            ? c.success.withOpacity(0.06)
                            : c.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: st.isDone
                            ? c.success.withOpacity(0.15) : c.border)),
                      child: Row(children: [
                        Icon(st.isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                            color: st.isDone
                                ? c.success : c.mutedForeground,
                            size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(st.title,
                            style: TextStyle(fontSize: 15,
                              color: st.isDone
                                  ? c.mutedForeground : c.primary,
                              decoration: st.isDone
                                  ? TextDecoration.lineThrough : null,
                            ))),
                      ]),
                    ),
                  ),
                );
              }),
            ],

            // Photos section
            const SizedBox(height: 16),
            Row(children: [
              Text('📸 Зураг', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600, color: c.primary)),
              const Spacer(),
              if (t.photoCount > 0)
                Text('${t.photoCount} зураг',
                    style: TextStyle(fontSize: 14,
                        color: c.mutedForeground)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              if (t.hasPhoto) ...List.generate(
                  t.photoCount.clamp(0, 3), (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border)),
                  child: Icon(Icons.image_rounded,
                      color: c.mutedForeground, size: 28)),
              )),
              if (!done)
                InkWell(
                  onTap: widget.onPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: c.brandGreen.withOpacity(0.2),
                          style: BorderStyle.solid)),
                    child: Icon(Icons.add_a_photo_rounded,
                        color: c.brandGreen, size: 24)),
                ),
            ]),

            const SizedBox(height: 24),
          ]),
        )),

        // Bottom actions
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            border: Border(
                top: BorderSide(color: c.border))),
          child: Row(children: [
            if (!done && t.status == TaskStatus.pending)
              Expanded(child: ElevatedButton.icon(
                onPressed: () {
                  widget.onStatusChange();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Эхлэх'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              )),
            if (!done && t.status == TaskStatus.inProgress)
              Expanded(child: ElevatedButton.icon(
                onPressed: () {
                  widget.onStatusChange();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Дуусгах'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              )),
            if (done)
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: c.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: c.success.withOpacity(0.2))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.check_circle, color: c.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Даалгавар дууссан',
                      style: TextStyle(fontWeight: FontWeight.w600,
                          color: c.success)),
                ]),
              )),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.c, required this.icon,
      required this.label, required this.value});
  final AppColorScheme c; final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext _) => Row(children: [
    Icon(icon, size: 18, color: c.mutedForeground),
    const SizedBox(width: 8),
    SizedBox(width: 80, child: Text(label,
        style: TextStyle(fontSize: 14, color: c.mutedForeground))),
    Expanded(child: Text(value,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
            color: c.primary))),
  ]);
}

Future<void> showTaskDetail(BuildContext context,
    {required CleaningTask task,
    required VoidCallback onStatusChange,
    required void Function(int) onSubtaskToggle,
    required VoidCallback onPhoto}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskDetailModal(task: task,
        onStatusChange: onStatusChange,
        onSubtaskToggle: onSubtaskToggle,
        onPhoto: onPhoto),
  );
}
