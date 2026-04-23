import 'dart:io';

import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../models/task_model.dart';
import '../services/image_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/socket_service.dart';
import '../services/timezone_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_detail_modal.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CleaningTask> _allTasks = [];
  bool _loading = true;
  String _filter = 'all';
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _loadTasks();
    ProjectService.activeProject.addListener(_onProjectChanged);
    SocketService.onTaskCreated(_onSocketUpdate);
    SocketService.onTaskUpdated(_onSocketUpdate);
  }

  void _onSocketUpdate(dynamic _) {
    if (mounted) _loadTasks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    ProjectService.activeProject.removeListener(_onProjectChanged);
    SocketService.offTaskCreated(_onSocketUpdate);
    SocketService.offTaskUpdated(_onSocketUpdate);
    super.dispose();
  }


  void _onProjectChanged() {
    if (mounted) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final activeProjectId = ProjectService.activeProject.value?.id;
    
    final apiTasks = activeProjectId != null 
        ? await TaskService.byProject(activeProjectId)
        : await TaskService.myTasks();
    if (!mounted) return;

    final today = stripTime(TimezoneService.nowMongolia());
    final List<CleaningTask> loaded = [];

    for (var t in apiTasks) {
      final ct = CleaningTask.fromApi(t);
      final d = stripTime(ct.date);

      // Include if past day OR today
      if (d.isBefore(today) || d == today) {
        loaded.add(ct);
      }
    }

    setState(() {
      _allTasks = loaded;
      _loading = false;
    });
  }

  Future<void> _loadSavedPhotos() async {
    for (final t in _allTasks) {
      final photos = await ImageService.getPhotos(t.id);
      if (photos.isNotEmpty && mounted) {
        setState(() {
          t.photoPaths.clear();
          t.photoPaths.addAll(photos);
          t.hasPhoto = true;
          t.photoCount = photos.length;
        });
      }
    }
  }

  List<CleaningTask> get _filteredTasks {
    var tasks = List<CleaningTask>.from(_allTasks);

    if (_filter == 'completed') {
      tasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    } else if (_filter == 'overdue') {
      tasks = tasks.where((t) => t.status == TaskStatus.overdue).toList();
    } else if (_filter == 'inProgress') {
      tasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.location.toLowerCase().contains(q)
      ).toList();
    }

    tasks.sort((a, b) => b.date.compareTo(a.date));
    return tasks;
  }

  Map<DateTime, List<CleaningTask>> get _groupedTasks {
    final map = <DateTime, List<CleaningTask>>{};
    for (final t in _filteredTasks) {
      final key = stripTime(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending: return c.warningOrange;
      case TaskStatus.inProgress: return c.info;
      case TaskStatus.completed: return c.success;
      case TaskStatus.overdue: return c.destructive;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return 'Хүлээгдэж буй';
      case TaskStatus.inProgress: return 'Явагдаж буй';
      case TaskStatus.completed: return 'Дууссан';
      case TaskStatus.overdue: return 'Хугацаа хэтэрсэн';
    }
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return Icons.schedule_rounded;
      case TaskStatus.inProgress: return Icons.play_circle_rounded;
      case TaskStatus.completed: return Icons.check_circle_rounded;
      case TaskStatus.overdue: return Icons.error_rounded;
    }
  }

  String _fmtDate(DateTime d) {
    final today = stripTime(TimezoneService.nowMongolia());
    final yesterday = today.subtract(const Duration(days: 1));
    final dt = stripTime(d);
    if (dt == today) return 'Өнөөдөр';
    if (dt == yesterday) return 'Өчигдөр';
    const dayNames = ['', 'Дав', 'Мяг', 'Лха', 'Пүр', 'Баа', 'Бям', 'Ням'];
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} (${dayNames[d.weekday]})';
  }

  void _setFilter(String filter) {
    setState(() => _filter = filter);
    // Scroll down past the stat cards to show the task list
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          220,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final grouped = _groupedTasks;
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Counts always from all tasks, not filtered
    final completedCount = _allTasks.where(
        (t) => t.status == TaskStatus.completed).length;
    final overdueCount = _allTasks.where(
        (t) => t.status == TaskStatus.overdue).length;
    final inProgressCount = _allTasks.where(
        (t) => t.status == TaskStatus.inProgress).length;


    final activeProject = ProjectService.activeProject.value;
    final title = activeProject?.ner ?? 'Бүх төсөл';

    return Scaffold(
      appBar: AppBar(
        title: Text('$title - Түүх'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               
              if (_loading)
                Center(child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: c.brandGreen, strokeWidth: 2.5),
                ))
              else ...[
                // ── Stat Cards ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      c: c,
                      label: 'Нийт',
                      count: _allTasks.length,
                      color: c.primary,
                      icon: Icons.assignment_rounded,
                      isActive: _filter == 'all',
                      onTap: () => _setFilter('all'),
                    ),
                    _StatCard(
                      c: c,
                      label: 'Дууссан',
                      count: completedCount,
                      color: c.success,
                      icon: Icons.check_circle_rounded,
                      isActive: _filter == 'completed',
                      onTap: () => _setFilter('completed'),
                    ),
                    _StatCard(
                      c: c,
                      label: 'Идэвхтэй',
                      count: inProgressCount,
                      color: c.info,
                      icon: Icons.play_circle_rounded,
                      isActive: _filter == 'inProgress',
                      onTap: () => _setFilter('inProgress'),
                    ),
                    _StatCard(
                      c: c,
                      label: 'Хэтэрсэн',
                      count: overdueCount,
                      color: c.destructive,
                      icon: Icons.error_rounded,
                      isActive: _filter == 'overdue',
                      onTap: () => _setFilter('overdue'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

              // ── Search ──
              Container(
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: c.primary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Даалгавар хайх...',
                    hintStyle: TextStyle(color: c.mutedForeground, fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: c.mutedForeground),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Filters ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: 'Бүгд', value: 'all',
                      selected: _filter, c: c,
                      onTap: () => _setFilter('all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Дууссан', value: 'completed',
                      selected: _filter, c: c, color: c.success,
                      onTap: () => _setFilter('completed')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Явагдаж буй', value: 'inProgress',
                      selected: _filter, c: c, color: c.info,
                      onTap: () => _setFilter('inProgress')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Хэтэрсэн', value: 'overdue',
                      selected: _filter, c: c, color: c.destructive,
                      onTap: () => _setFilter('overdue')),
                ]),
              ),

              const SizedBox(height: 14),

              // ── Result count ──
              Text('${_filteredTasks.length} даалгавар',
                  style: TextStyle(fontSize: 14, color: c.mutedForeground)),
              const SizedBox(height: 10),

              // ── Grouped tasks ──
              if (dates.isEmpty)
                _EmptyState(c: c)
              else
                ...dates.map((date) {
                  final dayTasks = grouped[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_fmtDate(date),
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.brandGreen)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Divider(color: c.border)),
                          const SizedBox(width: 8),
                          Text('${dayTasks.length}',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.mutedForeground)),
                        ]),
                      ),
                      ...dayTasks.map((t) => _ExpandableHistoryCard(
                        task: t, c: c,
                        statusColor: _statusColor(t.status, c),
                        statusLabel: _statusLabel(t.status),
                        statusIcon: _statusIcon(t.status),
                      )),
                      const SizedBox(height: 6),
                    ],
                  );
                }),
              ], // End else
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Stat Card
// ═══════════════════════════════════════
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.c,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
  final AppColorScheme c;
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : color.withOpacity(0.1),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.chevron_right_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════
//  Filter Chip
// ═══════════════════════════════════════
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value,
      required this.selected, required this.c,
      required this.onTap, this.color});
  final String label, value, selected;
  final AppColorScheme c;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isActive = selected == value;
    final chipColor = color ?? c.brandGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? chipColor : c.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? chipColor : c.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : c.mutedForeground)),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Expandable History Card
// ═══════════════════════════════════════
class _ExpandableHistoryCard extends StatefulWidget {
  const _ExpandableHistoryCard({required this.task, required this.c,
      required this.statusColor, required this.statusLabel,
      required this.statusIcon});
  final CleaningTask task;
  final AppColorScheme c;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;

  @override
  State<_ExpandableHistoryCard> createState() => _ExpandableHistoryCardState();
}

class _ExpandableHistoryCardState extends State<_ExpandableHistoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final c = widget.c;
    final sc = widget.statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _expanded ? sc.withOpacity(0.3) : c.border),
      ),
      child: Column(children: [
        // ── Top Row (always visible, tappable) ──
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                // Status icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.statusIcon, color: sc, size: 22),
                ),
                const SizedBox(width: 12),
                // Title + location
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: c.primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.place_outlined, size: 13,
                          color: c.mutedForeground),
                      const SizedBox(width: 3),
                      Expanded(child: Text(t.location,
                          style: TextStyle(fontSize: 13,
                              color: c.mutedForeground),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                )),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc,
                    borderRadius: BorderRadius.circular(999)),
                  child: Text(widget.statusLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              // Info bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.schedule_rounded, size: 14,
                      color: c.mutedForeground),
                  const SizedBox(width: 4),
                  Text(t.timeRange, style: TextStyle(fontSize: 13,
                      color: c.primary, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 14),
                  Icon(Icons.layers_outlined, size: 14,
                      color: c.mutedForeground),
                  const SizedBox(width: 4),
                  Text(t.floor, style: TextStyle(fontSize: 13,
                      color: c.primary)),
                  const SizedBox(width: 14),
                  // Photo indicator (always visible)
                  Icon(Icons.camera_alt_rounded, size: 14,
                      color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                          ? c.brandGreen : c.mutedForeground.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text('${t.photoPaths.isNotEmpty ? t.photoPaths.length : t.photoCount}', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: (t.photoPaths.isNotEmpty || t.hasPhoto)
                          ? c.brandGreen : c.mutedForeground.withOpacity(0.4))),
                  const Spacer(),
                  // Expand indicator
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: c.mutedForeground),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Expanded Detail Section ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: _buildDetails(c, sc),
        ),
      ]),
    );
  }

  Widget _buildDetails(AppColorScheme c, Color sc) {
    final t = widget.task;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: c.border, height: 1),
          const SizedBox(height: 12),

          // ── Info grid ──
          _DetailRow(icon: Icons.person_outline, label: 'Удирдагч',
              value: t.supervisor, c: c),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.timer_outlined, label: 'Төлөвлөсөн',
              value: '${t.estimatedMinutes} мин', c: c),
          if (t.status == TaskStatus.completed && t.completedAt != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Дууссан',
              value: '${t.completedAt!.hour.toString().padLeft(2, '0')}:${t.completedAt!.minute.toString().padLeft(2, '0')}',
              c: c,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Зарцуулсан',
              value: t.formattedElapsedHMS,
              c: c,
            ),
          ],

          // ── Notes ──
          if (t.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.chart4.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.chart4.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тэмдэглэл', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: c.primary)),
                  const SizedBox(height: 4),
                  Text(t.notes, style: TextStyle(fontSize: 14,
                      color: c.primary, height: 1.4)),
                ],
              ),
            ),
          ],

          // ── Subtasks ──
          if (t.subtasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text('☑ Дэд даалгавар', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: c.primary)),
              const Spacer(),
              Text('${t.subtasksDone}/${t.subtasks.length}',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: c.brandGreen)),
            ]),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t.subtaskProgress,
                minHeight: 5,
                backgroundColor: c.muted,
                valueColor: AlwaysStoppedAnimation(c.brandGreen),
              ),
            ),
            const SizedBox(height: 8),
            ...t.subtasks.map((st) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(
                  st.isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: st.isDone ? c.success : c.mutedForeground,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(st.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: st.isDone ? c.mutedForeground : c.primary,
                      decoration: st.isDone
                          ? TextDecoration.lineThrough : null,
                    ))),
              ]),
            )),
          ],

          // ── Photos ──
          if (t.photoPaths.isNotEmpty || t.hasPhoto) ...[
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.camera_alt_rounded, size: 16,
                  color: c.mutedForeground),
              const SizedBox(width: 6),
              Text('${t.photoPaths.isNotEmpty ? t.photoPaths.length : t.photoCount} зураг хавсаргасан',
                style: TextStyle(fontSize: 13,
                    color: c.mutedForeground)),
              const Spacer(),
              Icon(Icons.verified_rounded, size: 16,
                  color: c.success),
              const SizedBox(width: 4),
              Text('Баталгаажсан', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w500, color: c.success)),
            ]),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ...t.photoPaths.map((path) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _showFullPhoto(context, path, c),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: File(path).existsSync()
                        ? Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover)
                        : Container(width: 80, height: 80, color: c.muted, child: Icon(Icons.broken_image, color: c.mutedForeground, size: 20)),
                    ),
                  ),
                )),
                if (t.photoPaths.isEmpty && t.hasPhoto)
                  ...List.generate(t.photoCount, (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=200&auto=format&fit=crop',
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: c.muted),
                          ),
                          Container(width: 80, height: 80, color: Colors.black12),
                          const Positioned(right: 4, bottom: 4, child: Icon(Icons.verified_rounded, color: Colors.white70, size: 16)),
                        ],
                      ),
                    ),
                  )),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String path, AppColorScheme c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: path.startsWith('http') 
                  ? Image.network(path, fit: BoxFit.contain, width: double.infinity)
                  : Image.file(File(path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Detail Row
// ═══════════════════════════════════════
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label,
      required this.value, required this.c});
  final IconData icon;
  final String label, value;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: c.mutedForeground),
      const SizedBox(width: 6),
      SizedBox(width: 80, child: Text(label,
          style: TextStyle(fontSize: 13, color: c.mutedForeground))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w500, color: c.primary))),
    ]);
  }
}

// ═══════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.c});
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_rounded, size: 56, color: c.border),
          const SizedBox(height: 12),
          Text('Даалгавар олдсонгүй', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: c.mutedForeground)),
          const SizedBox(height: 4),
          Text('Шүүлтүүрийг өөрчилж үзнэ үү', style: TextStyle(
              fontSize: 14, color: c.mutedForeground)),
        ]),
      ),
    );
  }
}
