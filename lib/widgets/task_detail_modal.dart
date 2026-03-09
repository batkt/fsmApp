import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class TaskDetailModal extends StatefulWidget {
  const TaskDetailModal({
    super.key,
    required this.task,
    required this.onStatusChange,
    required this.onSubtaskToggle,
    required this.onPhoto,
  });
  final CleaningTask task;
  final VoidCallback onStatusChange;
  final Future<void> Function(int) onSubtaskToggle;
  final Future<void> Function() onPhoto;

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  CleaningTask get t => widget.task;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgressTimer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // Only start timer if task is in progress
    if (t.status == TaskStatus.inProgress) {
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && t.status == TaskStatus.inProgress) {
          setState(() {
            // Force rebuild to update elapsed time
          });
        } else {
          timer.cancel();
          _progressTimer = null;
        }
      });
    }
  }

  Color _prioColor(TaskPriority p, AppColorScheme c) {
    switch (p) {
      case TaskPriority.high:
        return c.destructive;
      case TaskPriority.medium:
        return c.warningOrange;
      case TaskPriority.low:
        return c.success;
    }
  }

  String _prioLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'Яаралтай';
      case TaskPriority.medium:
        return 'Хэвийн';
      case TaskPriority.low:
        return 'Бага';
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Хүлээгдэж буй';
      case TaskStatus.inProgress:
        return 'Явагдаж буй';
      case TaskStatus.completed:
        return 'Дууссан';
      case TaskStatus.overdue:
        return 'Хугацаа хэтэрсэн';
    }
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending:
        return c.warningOrange;
      case TaskStatus.inProgress:
        return c.info;
      case TaskStatus.completed:
        return c.success;
      case TaskStatus.overdue:
        return c.destructive;
    }
  }

  String _fmt(TimeOfDay td) =>
      '${td.hour.toString().padLeft(2, '0')}:${td.minute.toString().padLeft(2, '0')}';

  void _showFullPhoto(BuildContext context, String path, AppColorScheme c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(context.rSpacing(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rRadius(16))),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.rRadius(16)),
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: context.rSpacing(8),
              right: context.rSpacing(8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: context.rIconSize(28),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: EdgeInsets.all(context.rSpacing(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNetworkPhoto(BuildContext context, String url, AppColorScheme c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(context.rSpacing(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rRadius(16))),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.rRadius(16)),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: context.rSpacing(400),
                    color: Colors.grey[900],
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white70,
                        size: context.rIconSize(64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: context.rSpacing(8),
              right: context.rSpacing(8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: context.rIconSize(28),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: EdgeInsets.all(context.rSpacing(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sc = _statusColor(t.status, c);
    final pc = _prioColor(t.priority, c);
    final done = t.status == TaskStatus.completed;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.rRadius(24))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: context.rSpacing(12)),
            width: context.rSpacing(40),
            height: context.rSpacing(4),
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(context.rRadius(2)),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rSpacing(20),
              context.rSpacing(16),
              context.rSpacing(20),
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: context.rSpacing(54),
                  height: context.rSpacing(54),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.brandGreen.withOpacity(0.15), c.brandGreen.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(context.rRadius(16)),
                  ),
                  child: Icon(
                    Icons.cleaning_services_rounded,
                    color: c.brandGreen,
                    size: context.rIconSize(28),
                  ),
                ),
                SizedBox(width: context.rSpacing(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontSize: context.rFontSize(18),
                          fontWeight: FontWeight.bold,
                          color: c.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: context.rSpacing(4)),
                      Wrap(
                        spacing: context.rSpacing(8),
                        runSpacing: context.rSpacing(8),
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rSpacing(10),
                              vertical: context.rSpacing(4),
                            ),
                            decoration: BoxDecoration(
                              color: sc.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(context.rRadius(20)),
                              border: Border.all(color: sc.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: context.rSpacing(6),
                                  height: context.rSpacing(6),
                                  decoration: BoxDecoration(
                                    color: sc,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.rSpacing(6)),
                                Text(
                                  _statusLabel(t.status),
                                  style: TextStyle(
                                    fontSize: context.rFontSize(11),
                                    fontWeight: FontWeight.w700,
                                    color: sc,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rSpacing(10),
                              vertical: context.rSpacing(4),
                            ),
                            decoration: BoxDecoration(
                              color: pc.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.rRadius(20)),
                              border: Border.all(color: pc.withOpacity(0.2)),
                            ),
                            child: Text(
                              _prioLabel(t.priority),
                              style: TextStyle(
                                fontSize: context.rFontSize(11),
                                fontWeight: FontWeight.w700,
                                color: pc,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.rSpacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Grid
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rSpacing(16)),
                    decoration: BoxDecoration(
                      color: c.cardBackground,
                      borderRadius: BorderRadius.circular(context.rRadius(16)),
                      border: Border.all(color: c.border.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          c: c,
                          icon: Icons.place_rounded,
                          label: 'БАЙРШИЛ',
                          value: t.location,
                        ),
                        Divider(height: context.rSpacing(24), color: c.border.withOpacity(0.5)),
                        _InfoRow(
                          c: c,
                          icon: Icons.layers_rounded,
                          label: 'ДАВХАР',
                          value: t.floor,
                        ),
                        Divider(height: context.rSpacing(24), color: c.border.withOpacity(0.5)),
                        _InfoRow(
                          c: c,
                          icon: Icons.access_time_filled_rounded,
                          label: 'ХУГАЦАА',
                          value: '${_fmt(t.startTime)} - ${_fmt(t.endTime)}',
                        ),
                        Divider(height: context.rSpacing(24), color: c.border.withOpacity(0.5)),
                        _ProgressRow(task: t, c: c),
                      ],
                    ),
                  ),

                  // Notes
                  if (t.notes.isNotEmpty) ...[
                    SizedBox(height: context.rSpacing(24)),
                    Container(
                      padding: EdgeInsets.all(context.rSpacing(16)),
                      decoration: BoxDecoration(
                        color: c.cardBackground,
                        borderRadius: BorderRadius.circular(context.rRadius(16)),
                        border: Border.all(color: c.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(context.rSpacing(6)),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.description_rounded,
                                  size: context.rIconSize(16),
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(width: context.rSpacing(10)),
                              Text(
                                'ТАЙЛБАР',
                                style: TextStyle(
                                  fontSize: context.rFontSize(12),
                                  fontWeight: FontWeight.w700,
                                  color: c.mutedForeground,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rSpacing(12)),
                          Text(
                            t.notes,
                            style: TextStyle(
                              fontSize: context.rFontSize(14),
                              color: c.primary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Subtasks
                  if (t.subtasks.isNotEmpty) ...[
                    SizedBox(height: context.rSpacing(24)),
                    Container(
                      padding: EdgeInsets.all(context.rSpacing(16)),
                      decoration: BoxDecoration(
                        color: c.cardBackground,
                        borderRadius: BorderRadius.circular(context.rRadius(16)),
                        border: Border.all(color: c.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(context.rSpacing(6)),
                                decoration: BoxDecoration(
                                  color: c.brandGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.checklist_rtl_rounded,
                                  size: context.rIconSize(16),
                                  color: c.brandGreen,
                                ),
                              ),
                              SizedBox(width: context.rSpacing(10)),
                              Text(
                                'ДЭД ДААЛГАВАРУУД',
                                style: TextStyle(
                                  fontSize: context.rFontSize(12),
                                  fontWeight: FontWeight.w700,
                                  color: c.mutedForeground,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: context.rSpacing(8), vertical: context.rSpacing(2)),
                                decoration: BoxDecoration(
                                  color: c.brandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(context.rRadius(10)),
                                ),
                                child: Text(
                                  '${t.subtasksDone}/${t.subtasks.length}',
                                  style: TextStyle(
                                    fontSize: context.rFontSize(12),
                                    fontWeight: FontWeight.bold,
                                    color: c.brandGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rSpacing(16)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(context.rRadius(10)),
                            child: LinearProgressIndicator(
                              value: t.subtaskProgress,
                              minHeight: context.rSpacing(8),
                              backgroundColor: c.muted,
                              valueColor: AlwaysStoppedAnimation(c.brandGreen),
                            ),
                          ),
                          SizedBox(height: context.rSpacing(16)),
                          ...List.generate(t.subtasks.length, (i) {
                            final st = t.subtasks[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: context.rSpacing(8)),
                              child: InkWell(
                                onTap: done
                                    ? null
                                    : () async {
                                        setState(() => st.isDone = !st.isDone);
                                        await widget.onSubtaskToggle(i);
                                      },
                                borderRadius: BorderRadius.circular(context.rRadius(12)),
                                child: Container(
                                  padding: EdgeInsets.all(context.rSpacing(12)),
                                  decoration: BoxDecoration(
                                    color: st.isDone
                                        ? c.success.withOpacity(0.04)
                                        : c.secondary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(context.rRadius(12)),
                                    border: Border.all(
                                      color: st.isDone
                                          ? c.success.withOpacity(0.2)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: EdgeInsets.all(context.rSpacing(2)),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: st.isDone ? c.success : Colors.transparent,
                                          border: Border.all(
                                            color: st.isDone ? c.success : c.mutedForeground.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: context.rIconSize(14),
                                          color: st.isDone ? Colors.white : Colors.transparent,
                                        ),
                                      ),
                                      SizedBox(width: context.rSpacing(12)),
                                      Expanded(
                                        child: Text(
                                          st.title,
                                          style: TextStyle(
                                            fontSize: context.rFontSize(14),
                                            fontWeight: st.isDone ? FontWeight.w500 : FontWeight.w400,
                                            color: st.isDone
                                                ? c.mutedForeground
                                                : c.primary,
                                            decoration: st.isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Photos section - Show both types of images separately
                  SizedBox(height: context.rSpacing(16)),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original task images
                        if (t.hariutsagchZurag.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    size: context.rIconSize(18),
                                    color: c.info,
                                  ),
                                  SizedBox(width: context.rSpacing(8)),
                                  Text(
                                    'АНХНЫ ЗУРГУУД',
                                    style: TextStyle(
                                      fontSize: context.rFontSize(12),
                                      fontWeight: FontWeight.w700,
                                      color: c.mutedForeground,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${t.hariutsagchZurag.length}',
                                    style: TextStyle(
                                      fontSize: context.rFontSize(12),
                                      fontWeight: FontWeight.bold,
                                      color: c.info,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rSpacing(12)),
                              SizedBox(
                                height: context.rSpacing(120),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: t.hariutsagchZurag.length,
                                  separatorBuilder: (_, __) => SizedBox(width: context.rSpacing(12)),
                                  itemBuilder: (ctx, i) {
                                    final zurag = t.hariutsagchZurag[i];
                                    final imageUrl = zurag.zamNer ?? zurag.fileNer ?? '';
                                    if (imageUrl.isEmpty) return const SizedBox.shrink();

                                    final fullUrl = imageUrl.startsWith('http')
                                        ? imageUrl
                                        : '${ApiService.baseUrl}/$imageUrl';

                                    return GestureDetector(
                                      onTap: () => _showNetworkPhoto(context, fullUrl, c),
                                      child: Hero(
                                        tag: 'network_$fullUrl',
                                        child: Container(
                                          width: context.rSpacing(120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(context.rRadius(16)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(context.rRadius(16)),
                                            child: Image.network(
                                              fullUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  color: c.muted,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: progress.expectedTotalBytes != null
                                                          ? progress.cumulativeBytesLoaded /
                                                              progress.expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => Container(
                                                color: c.muted,
                                                child: Icon(Icons.broken_image_rounded, color: c.mutedForeground),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rSpacing(24)),
                        ],

                        // Employee uploaded images
                        if (t.ajiltanZurag.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_camera_rounded,
                                    size: context.rIconSize(18),
                                    color: c.brandGreen,
                                  ),
                                  SizedBox(width: context.rSpacing(8)),
                                  Text(
                                    'АЖИЛТНЫ ЗУРГУУД',
                                    style: TextStyle(
                                      fontSize: context.rFontSize(12),
                                      fontWeight: FontWeight.w700,
                                      color: c.mutedForeground,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${t.ajiltanZurag.length}',
                                    style: TextStyle(
                                      fontSize: context.rFontSize(12),
                                      fontWeight: FontWeight.bold,
                                      color: c.brandGreen,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rSpacing(12)),
                              SizedBox(
                                height: context.rSpacing(120),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: t.ajiltanZurag.length,
                                  separatorBuilder: (_, __) => SizedBox(width: context.rSpacing(12)),
                                  itemBuilder: (ctx, i) {
                                    final zurag = t.ajiltanZurag[i];
                                    final imageUrl = zurag.zamNer ?? zurag.fileNer ?? '';
                                    if (imageUrl.isEmpty) return const SizedBox.shrink();

                                    final fullUrl = imageUrl.startsWith('http')
                                        ? imageUrl
                                        : '${ApiService.baseUrl}/$imageUrl';

                                    return GestureDetector(
                                      onTap: () => _showNetworkPhoto(context, fullUrl, c),
                                      child: Hero(
                                        tag: 'employee_$fullUrl',
                                        child: Container(
                                          width: context.rSpacing(120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(context.rRadius(16)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(context.rRadius(16)),
                                            child: Image.network(
                                              fullUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  color: c.muted,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: progress.expectedTotalBytes != null
                                                          ? progress.cumulativeBytesLoaded /
                                                              progress.expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => Container(
                                                color: c.muted,
                                                child: Icon(Icons.broken_image_rounded, color: c.mutedForeground),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rSpacing(24)),
                        ],

                        // Local photos
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  size: context.rIconSize(18),
                                  color: c.brandGreen,
                                ),
                                SizedBox(width: context.rSpacing(8)),
                                Text(
                                  'ОДООГИЙН ЗУРГУУД',
                                  style: TextStyle(
                                    fontSize: context.rFontSize(12),
                                    fontWeight: FontWeight.w700,
                                    color: c.mutedForeground,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${t.photoPaths.length}',
                                  style: TextStyle(
                                    fontSize: context.rFontSize(12),
                                    fontWeight: FontWeight.bold,
                                    color: c.brandGreen,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.rSpacing(12)),
                            SizedBox(
                              height: context.rSpacing(120),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: t.photoPaths.length + (done ? 0 : 1),
                                separatorBuilder: (_, __) => SizedBox(width: context.rSpacing(12)),
                                itemBuilder: (ctx, i) {
                                  if (i == t.photoPaths.length) {
                                    return GestureDetector(
                                      onTap: () async {
                                        await widget.onPhoto();
                                        if (mounted) setState(() {});
                                      },
                                      child: Container(
                                        width: context.rSpacing(120),
                                        decoration: BoxDecoration(
                                          color: c.brandGreen.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(context.rRadius(16)),
                                          border: Border.all(
                                            color: c.brandGreen.withOpacity(0.2),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_rounded, color: c.brandGreen, size: context.rIconSize(28)),
                                            SizedBox(height: context.rSpacing(4)),
                                            Text(
                                              'Нэмэх',
                                              style: TextStyle(
                                                fontSize: context.rFontSize(12),
                                                fontWeight: FontWeight.bold,
                                                color: c.brandGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final path = t.photoPaths[i];
                                  final file = File(path);
                                  return GestureDetector(
                                    onTap: () => _showFullPhoto(context, path, c),
                                    child: Hero(
                                      tag: 'local_$path',
                                      child: Container(
                                        width: context.rSpacing(120),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(context.rRadius(16)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(context.rRadius(16)),
                                          child: file.existsSync()
                                              ? Image.file(file, fit: BoxFit.cover)
                                              : Container(
                                                  color: c.muted,
                                                  child: Icon(Icons.broken_image_rounded, color: c.mutedForeground),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.fromLTRB(
              context.rSpacing(20),
              context.rSpacing(16),
              context.rSpacing(20),
              context.rSpacing(24),
            ),
            decoration: BoxDecoration(
              color: c.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!done)
                  SizedBox(
                    width: double.infinity,
                    height: context.rSpacing(54),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onStatusChange();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.status == TaskStatus.inProgress
                            ? c.brandGreen
                            : c.primary,
                        foregroundColor: t.status == TaskStatus.inProgress ? Colors.white : c.primaryForeground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.rRadius(16)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            t.status == TaskStatus.inProgress
                                ? Icons.check_circle_rounded
                                : Icons.play_arrow_rounded,
                            size: context.rIconSize(24),
                          ),
                          SizedBox(width: context.rSpacing(12)),
                          Text(
                            t.status == TaskStatus.inProgress ? 'ДУУСГАХ' : 'ЭХЛЭХ',
                            style: TextStyle(
                              fontSize: context.rFontSize(16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: context.rSpacing(16)),
                    decoration: BoxDecoration(
                      color: c.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(context.rRadius(16)),
                      border: Border.all(color: c.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: c.success, size: context.rIconSize(22)),
                        SizedBox(width: context.rSpacing(12)),
                        Text(
                          'ДААЛГАВАР ДУУССАН',
                          style: TextStyle(
                            fontSize: context.rFontSize(14),
                            fontWeight: FontWeight.w800,
                            color: c.success,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: context.rSpacing(12)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: Size(double.infinity, context.rSpacing(48)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.rRadius(16)),
                    ),
                  ),
                  child: Text(
                    'ХААХ',
                    style: TextStyle(
                      fontSize: context.rFontSize(14),
                      fontWeight: FontWeight.w700,
                      color: c.mutedForeground,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.c,
    required this.icon,
    required this.label,
    required this.value,
  });
  final AppColorScheme c;
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.rSpacing(2)),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.rSpacing(8)),
          decoration: BoxDecoration(
            color: c.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(context.rRadius(10)),
          ),
          child: Icon(icon, size: context.rIconSize(18), color: c.mutedForeground),
        ),
        SizedBox(width: context.rSpacing(12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.rFontSize(11),
                color: c.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.rSpacing(2)),
            Text(
              value,
              style: TextStyle(
                fontSize: context.rFontSize(14),
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.task, required this.c});
  final CleaningTask task;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    final progress = task.progressPercentage;
    final elapsed = task.formattedElapsedTime;
    final total = task.formattedDuration;

    Color progressColor;
    Color textColor;
    IconData icon;

    switch (task.status) {
      case TaskStatus.overdue:
        progressColor = c.destructive;
        textColor = c.destructive;
        icon = Icons.error_outline_rounded;
        break;
      case TaskStatus.completed:
        progressColor = c.success;
        textColor = c.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case TaskStatus.inProgress:
        progressColor = c.info;
        textColor = c.info;
        icon = Icons.play_circle_outline_rounded;
        break;
      default:
        progressColor = c.mutedForeground;
        textColor = c.mutedForeground;
        icon = Icons.timer_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.rSpacing(8)),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.rRadius(10)),
              ),
              child: Icon(icon, size: context.rIconSize(18), color: textColor),
            ),
            SizedBox(width: context.rSpacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ЯВЦ',
                        style: TextStyle(
                          fontSize: context.rFontSize(11),
                          fontWeight: FontWeight.w600,
                          color: c.mutedForeground,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (progress != null)
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: context.rFontSize(12),
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.rSpacing(4)),
                  Row(
                    children: [
                      Text(
                        elapsed,
                        style: TextStyle(
                          fontSize: context.rFontSize(14),
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                      if (total != 'Тооцоолох боломжгүй') ...[
                        Text(
                          ' / $total',
                          style: TextStyle(
                            fontSize: context.rFontSize(13),
                            color: c.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          SizedBox(height: context.rSpacing(12)),
          Stack(
            children: [
              Container(
                height: context.rSpacing(10),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(context.rRadius(10)),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: MediaQuery.of(context).size.width * (progress > 1.0 ? 1.0 : progress),
                height: context.rSpacing(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [progressColor, progressColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(context.rRadius(10)),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

Future<void> showTaskDetail(
  BuildContext context, {
  required CleaningTask task,
  required VoidCallback onStatusChange,
  required Future<void> Function(int) onSubtaskToggle,
  required Future<void> Function() onPhoto,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskDetailModal(
      task: task,
      onStatusChange: onStatusChange,
      onSubtaskToggle: onSubtaskToggle,
      onPhoto: onPhoto,
    ),
  );
}
