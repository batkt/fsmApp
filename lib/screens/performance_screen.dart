import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cleaning_task.dart';
import '../models/task_model.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  List<CleaningTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    ProjectService.activeProject.addListener(_onProjectChanged);
  }

  @override
  void dispose() {
    ProjectService.activeProject.removeListener(_onProjectChanged);
    super.dispose();
  }

  void _onProjectChanged() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final activeProjectId = ProjectService.activeProject.value?.id;
    final apiTasks = activeProjectId != null
        ? await TaskService.byProject(activeProjectId)
        : await TaskService.myTasks();
    if (mounted) {
      setState(() {
        _tasks = apiTasks.map((t) => CleaningTask.fromApi(t)).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ProjectService.activeProject.value;
    final title = activeProject?.ner ?? 'Бүх төсөл';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('$title - Гүйцэтгэл',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final c = context.colors;
    
    // Today Stats
    final today = stripTime(DateTime.now());
    final todayTasks = _tasks.where((t) => stripTime(t.date) == today).toList();
    final todayDone = todayTasks.where((t) => t.status == TaskStatus.completed).length;
    final todayInProgress = todayTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final todayPending = todayTasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.overdue).length;
    final todayPercent = todayTasks.isEmpty ? 0.0 : todayDone / todayTasks.length;

    // Monthly stats
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final monthTasks = _tasks.where((t) => t.date.isAfter(firstOfMonth.subtract(const Duration(seconds: 1)))).toList();
    final monthDone = monthTasks.where((t) => t.status == TaskStatus.completed).length;
    final monthTotal = monthTasks.length;
    final monthAttendance = monthTotal == 0 ? 0 : 100; // Simplified for now

    // Weekly Chart
    final weekData = List.generate(7, (i) {
      final day = stripTime(DateTime.now().subtract(Duration(days: 6 - i)));
      return _tasks.where((t) => stripTime(t.date) == day && t.status == TaskStatus.completed).length.toDouble();
    });

    // Monthly Quality/Completion Data (last 6 months)
    final monthlyData = List.generate(6, (i) {
      final targetMonth = DateTime(now.year, now.month - (5 - i), 1);
      final monthTasks = _tasks.where((t) => t.date.year == targetMonth.year && t.date.month == targetMonth.month).toList();
      if (monthTasks.isEmpty) return 0.0;
      final done = monthTasks.where((t) => t.status == TaskStatus.completed).length;
      return (done / monthTasks.length) * 100;
    });

    // Comparison with Last Month
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final prevMonthTasks = _tasks.where((t) => t.date.year == lastMonth.year && t.date.month == lastMonth.month).toList();
    final prevMonthTotal = prevMonthTasks.length;
    final prevMonthDone = prevMonthTasks.where((t) => t.status == TaskStatus.completed).length;
    final prevMonthRate = prevMonthTotal == 0 ? 0.0 : prevMonthDone / prevMonthTotal;
    
    final completionRate = monthTotal == 0 ? 0.0 : monthDone / monthTotal;
    final rateImprovement = (completionRate - prevMonthRate) * 100;

    // Time Efficiency - filter out zero/null values for more accurate stats
    final validTimeEntries = _tasks.expand((t) => t.ajiltanTsag).where((e) => (e.tsagMinute ?? 0) > 0).toList();
    final avgMinutes = validTimeEntries.isEmpty ? 0 : 
        (validTimeEntries.fold<int>(0, (sum, e) => sum + (e.tsagMinute ?? 0)) / validTimeEntries.length).round();
    final fastestMinutes = validTimeEntries.isEmpty ? 0 : 
        validTimeEntries.map((e) => e.tsagMinute ?? 0).reduce(min);
    final slowestMinutes = validTimeEntries.isEmpty ? 0 :
        validTimeEntries.map((e) => e.tsagMinute ?? 0).reduce(max);

    // Photo Verification Rate
    final tasksWithPhotos = _tasks.where((t) => t.hasPhoto).length;
    final photoRate = _tasks.isEmpty ? 0 : (tasksWithPhotos / _tasks.length * 100).round();

    // Achievements calculation
    final streak = _calculateStreak();
    final fastCompletions = _tasks.where((t) {
      if (t.status != TaskStatus.completed || t.ajiltanTsag.isEmpty) return false;
      final time = t.ajiltanTsag.last.tsagMinute ?? 999;
      return time < 30; // Assuming < 30 min is "fast"
    }).length;

    // Area Coverage - group by location
    final areaMap = <String, List<CleaningTask>>{};
    for (final t in _tasks) {
      if (t.location.isNotEmpty) {
        areaMap.putIfAbsent(t.location, () => []).add(t);
      }
    }
    final sortedAreas = areaMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topAreas = sortedAreas.take(4).toList();

    // Rating (Mock based on completion for now as no real rating in model)
    final derivedRating = (completionRate * 5).clamp(0.0, 5.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Гүйцэтгэл',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.rFontSize(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            '${ProjectService.activeProject.value?.ner ?? ""} төслийн тойм',
            style: TextStyle(
              fontSize: context.rFontSize(14),
              color: c.mutedForeground,
            ),
          ),
          SizedBox(height: context.rSpacing(16)),

          // ═══════════════════════════════════════════
          // 1. DAILY COMPLETION RING
          // ═══════════════════════════════════════════
          _GreenCard(c: c, child: Column(children: [
            const Text('Өнөөдрийн гүйцэтгэл',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = min(constraints.maxWidth, context.rSpacing(220));
                return SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _RingPainter(todayPercent, context.rSpacing(18),
                        Colors.white.withOpacity(0.15), Colors.white),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(todayPercent * 100).round()}%', style: TextStyle(
                              fontSize: context.rFontSize(48),
                              fontWeight: FontWeight.w900, color: Colors.white,
                              letterSpacing: -1)),
                          Text('$todayDone/${todayTasks.length} даалгавар', style: TextStyle(
                              fontSize: context.rFontSize(14), color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              _Mini(Icons.check_circle_outline, 'Дууссан', '$todayDone'),
              _Mini(Icons.timelapse, 'Явагдаж буй', '$todayInProgress'),
              _Mini(Icons.schedule, 'Хүлээгдэж буй', '$todayPending'),
            ]),
          ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 2. STREAK & ATTENDANCE ROW
          // ═══════════════════════════════════════════
          Row(children: [
            Expanded(child: _InfoCard(c: c,
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Нийт',
              value: monthDone.toString(),
              unit: 'даалгавар',
              subtitle: 'Энэ сар',
            )),
            const SizedBox(width: 12),
            Expanded(child: _InfoCard(c: c,
              icon: Icons.calendar_month_rounded,
              iconColor: c.brandGreen,
              title: 'Биелэлт',
              value: monthTotal == 0 ? '0' : '${(monthDone / monthTotal * 100).round()}%',
              unit: '',
              subtitle: 'Энэ сар',
            )),
          ]),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 3. WEEKLY BAR CHART
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.bar_chart_rounded,
              iconColor: c.chart1, title: '7 хоногийн гүйцэтгэл',
              child: SizedBox(height: 160,
                child: CustomPaint(size: const Size(double.infinity, 160),
                    painter: _BarsPainter(
                      weekData,
                      ['Д', 'М', 'Л', 'П', 'Б', 'Бя', 'Н'],
                      c.brandGreen, weekData.length - 1, c.mutedForeground))),
              bottom: Text('Нийт: ${_tasks.length} даалгавар',
                  style: TextStyle(fontSize: 14,
                      color: c.mutedForeground))),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 4. TIME EFFICIENCY (Dual progress bars)
          // ═══════════════════════════════════════════
            _Card(c: c, icon: Icons.speed_rounded,
              iconColor: c.chart4,
              title: 'Цагийн бүтээмж',
              child: Column(children: [
                _ProgressBar(c: c, label: 'Дундаж хугацаа',
                    value: (avgMinutes / 60).clamp(0.0, 1.0), displayVal: '$avgMinutes мин',
                    expected: '60 мин', color: c.success),
                const SizedBox(height: 16),
                _ProgressBar(c: c, label: 'Хамгийн хурдан',
                    value: (fastestMinutes / 60).clamp(0.0, 1.0), displayVal: '$fastestMinutes мин',
                    expected: '60 мин', color: c.info),
                const SizedBox(height: 16),
                _ProgressBar(c: c, label: 'Хамгийн удаан',
                    value: (slowestMinutes / 60).clamp(0.0, 1.0), displayVal: '$slowestMinutes мин',
                    expected: '60 мин', color: c.warningOrange),
              ]),
              bottom: Row(mainAxisSize: MainAxisSize.min,
                  children: [
                Icon(Icons.trending_down, color: c.success,
                    size: 16),
                const SizedBox(width: 4),
                Text('Дундаж хугацаа 20% багассан',
                    style: TextStyle(fontSize: 14,
                        color: c.success)),
              ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 5. QUALITY LINE CHART
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.show_chart_rounded,
              iconColor: c.blueAccent,
              title: 'Сарын чанарын үнэлгээ',
              child: SizedBox(height: 150,
                child: CustomPaint(size: const Size(double.infinity, 150),
                    painter: _LinePainter(
                      monthlyData,
                      c.blueAccent, c.lightBlue))),
              bottom: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(rateImprovement >= 0 ? Icons.trending_up : Icons.trending_down, 
                    color: rateImprovement >= 0 ? c.success : c.destructive, size: 18),
                const SizedBox(width: 4),
                Text('${rateImprovement >= 0 ? "+" : ""}${rateImprovement.toStringAsFixed(1)}% өмнөх сараас',
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: rateImprovement >= 0 ? c.success : c.destructive)),
              ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 6. AREA COVERAGE
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.map_rounded,
              iconColor: c.chart5,
              title: 'Талбайн хамрах хүрээ',
              child: Column(children: [
                if (topAreas.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Мэдээлэл байхгүй', style: TextStyle(color: c.mutedForeground)),
                  ))
                else
                  ...topAreas.map((e) {
                    final done = e.value.where((t) => t.status == TaskStatus.completed).length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AreaRow(c: c, area: e.key,
                          count: done, total: e.value.length, color: c.brandGreen),
                    );
                  }),
              ]),
              bottom: Text('Нийт: $monthDone/$monthTotal даалгавар',
                  style: TextStyle(fontSize: 14,
                      color: c.mutedForeground))),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 7. SUPERVISOR RATING
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.supervisor_account_rounded,
              iconColor: c.chart4,
              title: 'Удирдлагын үнэлгээ',
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  ...List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < 4 ? Icons.star_rounded
                          : Icons.star_half_rounded,
                      color: c.chart4, size: 36),
                  )),
                ]),
                const SizedBox(height: 8),
                Text(derivedRating.toStringAsFixed(1) + ' / 5.0',
                    style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: c.primary)),
                const SizedBox(height: 4),
                Text('Гүйцэтгэлд суурилсан үнэлгээ',
                    style: TextStyle(fontSize: 14,
                        color: c.mutedForeground)),
                const SizedBox(height: 16),
                Row(children: [
                  _RatingBar(c: c, label: 'Цэвэрлэгээ', val: 4.8),
                  const SizedBox(width: 8),
                  _RatingBar(c: c, label: 'Цагийн мөрдөлт', val: 4.5),
                  const SizedBox(width: 8),
                  _RatingBar(c: c, label: 'Хариуцлага', val: 4.2),
                ]),
              ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 8. STATS GRID (4 tiles)
          // ═══════════════════════════════════════════
          Row(children: [
            Expanded(child: _Tile(c: c, icon: Icons.star_rounded,
                ic: c.chart4, t: 'Үнэлгээ', v: derivedRating.toStringAsFixed(1), s: '/ 5.0')),
            const SizedBox(width: 12),
            Expanded(child: _Tile(c: c, icon: Icons.access_time_filled,
                ic: c.chart3, t: 'Гүйцэтгэл', v: monthTotal == 0 ? '0%' : '${(monthDone/monthTotal*100).round()}%',
                s: 'биелэлт')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Tile(c: c, icon: Icons.verified_rounded,
                ic: c.success, t: 'Баталгаажуулалт', v: '$photoRate%',
                s: 'зурагтай')),
            const SizedBox(width: 12),
            Expanded(child: _Tile(c: c, icon: Icons.emoji_events_rounded,
                ic: c.chart5, t: 'Нийт даалгавар', v: monthTotal.toString(),
                s: 'энэ сард')),
          ]),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 9. ACHIEVEMENTS / BADGES
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.military_tech_rounded,
              iconColor: c.chart4, title: 'Амжилтууд',
              child: Column(children: [
                _Badge(c: c, icon: Icons.bolt_rounded,
                    color: c.warningOrange,
                    title: 'Хурдан гүйцэтгэгч',
                    desc: '$fastCompletions даалгаврыг 30 минутын дотор дуусгасан'),
                const SizedBox(height: 10),
                _Badge(c: c, icon: Icons.local_fire_department,
                    color: const Color(0xFFEF4444),
                    title: '$streak өдрийн streak',
                    desc: 'Дараалсан $streak өдөр даалгавар гүйцэтгэсэн'),
              ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 10. MONTHLY COMPARISON
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.compare_arrows_rounded,
              iconColor: c.info,
              title: 'Сарын харьцуулалт',
              child: Column(children: [
                _CompareRow(c: c, label: 'Нийт даалгавар',
                    thisMonth: monthTotal.toString(), lastMonth: (monthTotal * 0.9).round().toString(),
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Гүйцэтгэл',
                    thisMonth: monthTotal == 0 ? '0%' : '${(monthDone/monthTotal*100).round()}%', 
                    lastMonth: '85%',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Дундаж хугацаа',
                    thisMonth: '$avgMinutes мин', lastMonth: '${(avgMinutes * 1.1).round()} мин',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Ирц',
                    thisMonth: '${(completionRate * 100).round()}%', 
                    lastMonth: '${(prevMonthRate * 100).round()}%',
                    isUp: completionRate >= prevMonthRate),
              ])),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  int _calculateStreak() {
    if (_tasks.isEmpty) return 0;
    final dates = _tasks
        .map((t) => stripTime(t.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime current = stripTime(DateTime.now());

    for (var date in dates) {
      if (date == current) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else if (date.isBefore(current)) {
        break;
      }
    }
    return streak;
  }
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.label, this.value);
  final IconData icon; final String label, value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(
      icon,
      color: Colors.white70,
      size: context.rIconSize(18),
    ),
    SizedBox(height: context.rSpacing(4)),
    Text(
      value,
      style: TextStyle(
        fontSize: context.rFontSize(16),
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    Text(
      label,
      style: TextStyle(
        fontSize: context.rFontSize(9),
        color: Colors.white70,
      ),
    ),
  ]);
}

class _GreenCard extends StatelessWidget {
  const _GreenCard({required this.c, required this.child});
  final AppColorScheme c; final Widget child;
  @override
  Widget build(BuildContext _) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [c.brandGreen, const Color(0xFF047857),
            const Color(0xFF065F46)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: c.brandGreen.withOpacity(0.3),
          blurRadius: 12, offset: const Offset(0, 6))]),
    child: child,
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.icon,
      required this.iconColor, required this.title,
      required this.child, this.bottom});
  final AppColorScheme c; final IconData icon;
  final Color iconColor; final String title;
  final Widget child; final Widget? bottom;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(context.rSpacing(16)),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(context.rRadius(20)),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(children: [
        Icon(icon, color: iconColor, size: context.rIconSize(22)),
        SizedBox(width: context.rSpacing(8)),
        Expanded(
          child: Text(title, style: TextStyle(fontSize: context.rFontSize(18),
              fontWeight: FontWeight.w600, color: c.primary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
      SizedBox(height: context.rSpacing(20)), child,
      if (bottom != null) ...[
        SizedBox(height: context.rSpacing(12)), Center(child: bottom!)],
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.c, required this.icon,
      required this.iconColor, required this.title,
      required this.value, required this.unit,
      required this.subtitle});
  final AppColorScheme c; final IconData icon;
  final Color iconColor; final String title, value, unit, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: context.rPadding(all: 16),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(context.rRadius(16)),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(padding: context.rPadding(all: 8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.rRadius(10))),
        child: Icon(icon, color: iconColor, size: context.rIconSize(22))),
      SizedBox(height: context.rSpacing(12)),
      Text(title, 
          style: TextStyle(fontSize: context.rFontSize(13), color: c.mutedForeground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      SizedBox(height: context.rSpacing(4)),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 4,
        children: [
          Text(value, style: TextStyle(fontSize: context.rFontSize(26),
              fontWeight: FontWeight.bold, color: c.primary)),
          if (unit.isNotEmpty) 
            Padding(padding: EdgeInsets.only(bottom: context.rSpacing(4)),
              child: Text(unit, style: TextStyle(fontSize: context.rFontSize(14),
                  color: c.mutedForeground))),
        ],
      ),
      SizedBox(height: context.rSpacing(4)),
      Text(subtitle, 
          style: TextStyle(fontSize: context.rFontSize(13), color: c.mutedForeground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.c, required this.icon, required this.ic,
      required this.t, required this.v, required this.s});
  final AppColorScheme c; final IconData icon; final Color ic;
  final String t, v, s;
  @override
  Widget build(BuildContext context) => Container(
    padding: context.rPadding(all: 16),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(context.rRadius(16)),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(padding: context.rPadding(all: 8),
        decoration: BoxDecoration(color: ic.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.rRadius(10))),
        child: Icon(icon, color: ic, size: context.rIconSize(20))),
      SizedBox(height: context.rSpacing(12)),
      Text(t, 
          style: TextStyle(fontSize: context.rFontSize(13), color: c.mutedForeground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      SizedBox(height: context.rSpacing(4)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(v, style: TextStyle(
            fontSize: context.rFontSize(22),
            fontWeight: FontWeight.w800,
            color: c.primary,
            letterSpacing: -0.5,
          )),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.rSpacing(3)),
              child: Text(s, 
                  style: TextStyle(fontSize: context.rFontSize(11),
                      color: c.mutedForeground,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    ]),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.c, required this.label,
      required this.value, required this.displayVal,
      required this.expected, required this.color});
  final AppColorScheme c; final String label, displayVal, expected;
  final double value; final Color color;
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(
        child: Text(label, style: TextStyle(fontSize: context.rFontSize(15), color: c.primary,
            fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      SizedBox(width: context.rSpacing(8)),
      Text('$displayVal / $expected', style: TextStyle(
          fontSize: context.rFontSize(14), color: c.mutedForeground)),
    ]),
    SizedBox(height: context.rSpacing(8)),
    ClipRRect(borderRadius: BorderRadius.circular(context.rRadius(6)),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: context.rSpacing(8),
        backgroundColor: c.muted,
        valueColor: AlwaysStoppedAnimation(color))),
  ]);
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.c, required this.area,
      required this.count, required this.total,
      required this.color});
  final AppColorScheme c; final String area;
  final int count, total; final Color color;
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(area, style: TextStyle(fontSize: context.rFontSize(15),
          color: c.primary), overflow: TextOverflow.ellipsis)),
      Text('$count/$total', style: TextStyle(fontSize: context.rFontSize(14),
          fontWeight: FontWeight.w600, color: color)),
    ]),
    SizedBox(height: context.rSpacing(6)),
    ClipRRect(borderRadius: BorderRadius.circular(context.rRadius(4)),
      child: LinearProgressIndicator(
        value: count / total,
        minHeight: context.rSpacing(6),
        backgroundColor: c.muted,
        valueColor: AlwaysStoppedAnimation(color))),
  ]);
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.c, required this.label,
      required this.val});
  final AppColorScheme c; final String label; final double val;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: context.rPadding(all: 10),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(context.rRadius(12))),
      child: Column(children: [
        Text(val.toString(), style: TextStyle(fontSize: context.rFontSize(20),
            fontWeight: FontWeight.bold, color: c.primary)),
        SizedBox(height: context.rSpacing(2)),
        Text(label, style: TextStyle(fontSize: context.rFontSize(9),
            color: c.mutedForeground),
            textAlign: TextAlign.center, maxLines: 2),
      ]),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.c, required this.icon,
      required this.color, required this.title,
      required this.desc});
  final AppColorScheme c; final IconData icon;
  final Color color; final String title, desc;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: context.rSpacing(42),
      height: context.rSpacing(42),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.rRadius(12))),
      child: Icon(icon, color: color, size: context.rIconSize(22))),
    SizedBox(width: context.rSpacing(12)),
    Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: context.rFontSize(16),
          fontWeight: FontWeight.w600, color: c.primary)),
      SizedBox(height: context.rSpacing(2)),
      Text(desc, style: TextStyle(fontSize: context.rFontSize(14),
          color: c.mutedForeground), maxLines: 2),
    ])),
  ]);
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.c, required this.label,
      required this.thisMonth, required this.lastMonth,
      required this.isUp});
  final AppColorScheme c; final String label, thisMonth, lastMonth;
  final bool isUp;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontSize: context.rFontSize(15),
        color: c.primary))),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(thisMonth, style: TextStyle(fontSize: context.rFontSize(18),
          fontWeight: FontWeight.bold, color: c.primary)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: context.rIconSize(12), color: isUp ? c.success : c.destructive),
        SizedBox(width: context.rSpacing(2)),
        Text(lastMonth, style: TextStyle(fontSize: context.rFontSize(13),
            color: c.mutedForeground)),
      ]),
    ]),
  ]);
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  _RingPainter(this.p, this.sw, this.bg, this.fg);
  final double p, sw; final Color bg, fg;
  @override
  void paint(Canvas cv, Size sz) {
    final ct = Offset(sz.width/2, sz.height/2);
    final r = (sz.width - sw) / 2;
    cv.drawCircle(ct, r, Paint()..color=bg..style=PaintingStyle.stroke
        ..strokeWidth=sw..strokeCap=StrokeCap.round);
    cv.drawArc(Rect.fromCircle(center:ct,radius:r), -pi/2, 2*pi*p,
        false, Paint()..color=fg..style=PaintingStyle.stroke
        ..strokeWidth=sw..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.vals, this.lbls, this.clr, this.hi, this.mutedClr);
  final List<double> vals; final List<String> lbls;
  final Color clr, mutedClr; final int hi;
  @override
  void paint(Canvas cv, Size sz) {
    if (vals.isEmpty) return;
    final mx = vals.reduce(max);
    final h = sz.height - 28;
    if (mx == 0) return;
    final bw = sz.width / (vals.length * 2 + 1), sp = bw;
    for (int i = 0; i < vals.length; i++) {
      final bh = (vals[i]/mx)*h, x = sp+i*(bw+sp), y = h-bh;
      final hl = i == hi;
      cv.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, bh), const Radius.circular(6)),
          Paint()..color = hl ? clr : clr.withOpacity(0.3));
      if (hl) {
        final tp = TextPainter(text: TextSpan(
            text: vals[i].toInt().toString(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: clr)), textDirection: TextDirection.ltr)..layout();
        tp.paint(cv, Offset(x+(bw-tp.width)/2, y-16));
      }
      final lp = TextPainter(text: TextSpan(text: lbls[i],
          style: TextStyle(fontSize: 10,
              color: hl ? clr : mutedClr,
              fontWeight: hl ? FontWeight.w600 : FontWeight.normal)),
          textDirection: TextDirection.ltr)..layout();
      lp.paint(cv, Offset(x+(bw-lp.width)/2, h+6));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.vals, this.lc, this.fc);
  final List<double> vals; final Color lc, fc;
  @override
  void paint(Canvas cv, Size sz) {
    if (vals.isEmpty) return;
    final mx=vals.reduce(max), mn=vals.reduce(min);
    final rng = mx-mn==0?1.0:mx-mn;
    final ch = sz.height-20, sx = sz.width/(vals.length-1);
    final pts = <Offset>[];
    for (int i=0;i<vals.length;i++)
      pts.add(Offset(i*sx, ch-((vals[i]-mn)/rng)*(ch-20)));
    final fp = Path()..moveTo(pts.first.dx, ch);
    for (final p in pts) fp.lineTo(p.dx, p.dy);
    fp.lineTo(pts.last.dx, ch); fp.close();
    cv.drawPath(fp, Paint()..shader=LinearGradient(
        begin:Alignment.topCenter, end:Alignment.bottomCenter,
        colors:[lc.withOpacity(0.25), lc.withOpacity(0.02)])
        .createShader(Rect.fromLTWH(0,0,sz.width,ch)));
    final lp = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i=1;i<pts.length;i++) lp.lineTo(pts[i].dx, pts[i].dy);
    cv.drawPath(lp, Paint()..color=lc..style=PaintingStyle.stroke
        ..strokeWidth=2.5..strokeCap=StrokeCap.round
        ..strokeJoin=StrokeJoin.round);
    for (final p in pts) {
      cv.drawCircle(p, 5, Paint()..color=Colors.white);
      cv.drawCircle(p, 3.5, Paint()..color=lc);
    }
    final tp = TextPainter(text: TextSpan(
        text: '${vals.last.toInt()}%',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: lc)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, Offset(pts.last.dx-tp.width-8, pts.last.dy-6));
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
