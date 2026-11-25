import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Даалгаврын карт: зүүн талд төлөвийн өнгөт зураас, гол үйлдэл (Эхлэх /
/// Дуусгах) картан дээрээ шууд харагдана; дэд даалгавар, тэмдэглэл, зураг
/// дэлгэхэд гарна.
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
    if (widget.task.isDay) return 'Бүтэн өдөр';
    String f(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${f(widget.task.startTime)} – ${f(widget.task.endTime)}';
  }

  (String, Color) _prio(TaskPriority p, AppColorScheme c) => switch (p) {
        TaskPriority.high => ('Яаралтай', c.destructive),
        TaskPriority.medium => ('Дунд', c.warningOrange),
        TaskPriority.low => ('Энгийн', c.success),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = widget.task;
    final done = t.status == TaskStatus.completed;
    final prog = t.status == TaskStatus.inProgress;
    final sc = widget.statusColor;
    final (prioNer, prioUngu) = _prio(t.priority, c);
    final zuragToo = t.photoPaths.isNotEmpty ? t.photoPaths.length : t.photoCount;
    final r = context.rRadius(18);

    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(r),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: prog ? sc.withValues(alpha: 0.45) : c.border),
          ),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Төлөвийн өнгөт зураас
              Container(width: 5, color: sc),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: context.rPadding(left: 12, right: 12, top: 12, bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Цаг, ач холбогдол
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Wrap(spacing: 6, runSpacing: 6, children: [
                            _Chip(icon: Icons.schedule_rounded, text: _time(), ungu: c.brandGreen),
                            _Chip(text: prioNer, ungu: prioUngu),
                            if (t.isLoop)
                              const _Chip(icon: Icons.loop_rounded, text: 'Давтагдана', ungu: Color(0xFF8B5CF6)),
                          ]),
                        ),
                        context.rWidth(6),
                        _Chip(text: widget.statusLabel, ungu: sc),
                      ]),
                      context.rHeight(10),
                      Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rFontSize(16.5),
                          fontWeight: FontWeight.w500,
                          color: done ? c.mutedForeground : c.primary,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (t.location.isNotEmpty) ...[
                        context.rHeight(4),
                        Row(children: [
                          Icon(Icons.place_rounded, size: context.rIconSize(14), color: c.mutedForeground),
                          context.rWidth(3),
                          Expanded(
                            child: Text(t.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: context.rFontSize(13.5), color: c.mutedForeground)),
                          ),
                        ]),
                      ],
                      if (t.subtasks.isNotEmpty) ...[
                        context.rHeight(10),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: t.subtaskProgress,
                                minHeight: 5,
                                backgroundColor: c.brandGreen.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(c.success),
                              ),
                            ),
                          ),
                          context.rWidth(8),
                          Text('${t.subtasksDone}/${t.subtasks.length}',
                              style: TextStyle(fontSize: context.rFontSize(12.5), color: c.mutedForeground)),
                        ]),
                      ],
                      context.rHeight(12),
                      // Үйлдлүүд
                      Row(children: [
                        _IconTovch(
                          icon: Icons.chat_bubble_rounded,
                          ungu: c.brandGreen,
                          tooltip: 'Чат',
                          onTap: widget.onChat,
                        ),
                        context.rWidth(8),
                        _IconTovch(
                          icon: t.hasPhoto ? Icons.verified_rounded : Icons.camera_alt_rounded,
                          ungu: t.hasPhoto ? c.success : const Color(0xFF8B5CF6),
                          tooltip: 'Зураг',
                          too: zuragToo,
                          onTap: done ? null : widget.onAttachPhoto,
                        ),
                        const Spacer(),
                        if (!done)
                          _GolTovch(
                            text: prog ? 'Дуусгах' : 'Эхлэх',
                            icon: prog ? Icons.check_rounded : Icons.play_arrow_rounded,
                            gradient: prog
                                ? const [Color(0xFF34D399), Color(0xFF059669)]
                                : const [Color(0xFF5B8DEF), Color(0xFF315BB0)],
                            onTap: prog ? widget.onFinish : widget.onStart,
                          )
                        else
                          Row(children: [
                            Icon(Icons.check_circle_rounded, size: context.rIconSize(18), color: c.success),
                            context.rWidth(4),
                            Text('Дууссан', style: TextStyle(fontSize: context.rFontSize(13.5), color: c.success)),
                          ]),
                        if (t.subtasks.isNotEmpty || t.notes.isNotEmpty) ...[
                          context.rWidth(4),
                          IconButton(
                            tooltip: _expanded ? 'Хураах' : 'Дэлгэрэнгүй',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _expanded = !_expanded),
                            icon: AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.expand_more_rounded, color: c.mutedForeground),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                  // Дэлгэрэнгүй: дэд даалгавар, тэмдэглэл
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_expanded
                        ? const SizedBox(width: double.infinity)
                        : Container(
                            width: double.infinity,
                            color: c.brandGreen.withValues(alpha: 0.05),
                            padding: context.rPadding(left: 12, right: 12, top: 10, bottom: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              for (final st in t.subtasks.take(5))
                                Padding(
                                  padding: context.rPadding(bottom: 6),
                                  child: Row(children: [
                                    Icon(
                                      st.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: context.rIconSize(17),
                                      color: st.isDone ? c.success : c.mutedForeground,
                                    ),
                                    context.rWidth(8),
                                    Expanded(
                                      child: Text(st.title,
                                          style: TextStyle(
                                            fontSize: context.rFontSize(14),
                                            color: st.isDone ? c.mutedForeground : c.primary,
                                            decoration: st.isDone ? TextDecoration.lineThrough : null,
                                          )),
                                    ),
                                  ]),
                                ),
                              if (t.subtasks.length > 5)
                                Text('+${t.subtasks.length - 5} бусад — дарж дэлгэрэнгүй үзнэ үү',
                                    style: TextStyle(fontSize: context.rFontSize(13), color: c.brandGreen)),
                              if (t.notes.isNotEmpty) ...[
                                if (t.subtasks.isNotEmpty) context.rHeight(6),
                                Container(
                                  width: double.infinity,
                                  padding: context.rPadding(all: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(context.rRadius(12)),
                                  ),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Icon(Icons.sticky_note_2_rounded,
                                        size: context.rIconSize(16), color: const Color(0xFFD97706)),
                                    context.rWidth(8),
                                    Expanded(
                                      child: Text(t.notes,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: context.rFontSize(13.5), color: c.primary)),
                                    ),
                                  ]),
                                ),
                              ],
                            ]),
                          ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Жижиг өнгөт шошго
class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.ungu, this.icon});
  final String text;
  final Color ungu;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.rSymmetricPadding(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: context.rIconSize(13), color: ungu),
          context.rWidth(4),
        ],
        Text(text,
            style: TextStyle(
              fontSize: context.rFontSize(12),
              color: ungu,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ]),
    );
  }
}

/// Дугуй өнгөт дүрс товч (чат, зураг)
class _IconTovch extends StatelessWidget {
  const _IconTovch({required this.icon, required this.ungu, required this.tooltip, this.onTap, this.too = 0});
  final IconData icon;
  final Color ungu;
  final String tooltip;
  final VoidCallback? onTap;
  final int too;
  @override
  Widget build(BuildContext context) {
    final idevkhtei = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: ungu.withValues(alpha: idevkhtei ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: context.rSymmetricPadding(horizontal: too > 0 ? 10 : 9, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: context.rIconSize(17), color: ungu.withValues(alpha: idevkhtei ? 1 : 0.5)),
              if (too > 0) ...[
                context.rWidth(4),
                Text('$too', style: TextStyle(fontSize: context.rFontSize(12.5), color: ungu)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Гол үйлдлийн градиент товч (Эхлэх / Дуусгах)
class _GolTovch extends StatelessWidget {
  const _GolTovch({required this.text, required this.icon, required this.gradient, required this.onTap});
  final String text;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: context.rSymmetricPadding(horizontal: 16, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: context.rIconSize(18), color: Colors.white),
              context.rWidth(4),
              Text(text, style: TextStyle(fontSize: context.rFontSize(14), fontWeight: FontWeight.w500, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }
}
