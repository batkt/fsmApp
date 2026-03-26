import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cleaning_task.dart';
import '../models/task_model.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../services/kpi_service.dart';
import '../services/socket_service.dart';
import '../services/timezone_service.dart';
import '../widgets/app_toast.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  List<CleaningTask> _tasks = [];
  Map<String, dynamic>? _kpi;
  bool _loading = true;
  bool _refreshingKpi = false;
  DateTime _selectedDate = TimezoneService.nowMongolia();

  void _onSocketUpdate(dynamic _) {
    if (mounted) _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    ProjectService.activeProject.addListener(_onProjectChanged);
    SocketService.onTaskUpdated(_onSocketUpdate);
    SocketService.onTaskCreated(_onSocketUpdate);
    SocketService.onKpiUpdated(_onSocketUpdate);
  }

  @override
  void dispose() {
    ProjectService.activeProject.removeListener(_onProjectChanged);
    SocketService.offTaskUpdated(_onSocketUpdate);
    SocketService.offTaskCreated(_onSocketUpdate);
    SocketService.offKpiUpdated(_onSocketUpdate);
    super.dispose();
  }

  void _onProjectChanged() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final activeProjectId = ProjectService.activeProject.value?.id;
    
    // Run both in parallel
    final results = await Future.wait([
      activeProjectId != null
          ? TaskService.byProject(activeProjectId)
          : TaskService.myTasks(),
      KpiService.getMyKpi(),
    ]);

    final apiTasks = results[0] as List<ApiTask>;
    final kpiData = results[1] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        _tasks = apiTasks.map<CleaningTask>((t) => CleaningTask.fromApi(t)).toList();
        _kpi = kpiData;
        _loading = false;
      });
    }
  }

  Future<void> _refreshKpi() async {
    setState(() => _refreshingKpi = true);
    final success = await KpiService.refreshKpi();
    if (success) {
      final kpiData = await KpiService.getMyKpi();
      if (mounted) {
        setState(() {
          _kpi = kpiData;
          _refreshingKpi = false;
        });
        AppToast.show(context, 'KPI шинэчлэгдлээ', icon: Icons.check_circle_rounded);
      }
    } else {
      if (mounted) {
        setState(() => _refreshingKpi = false);
        AppToast.show(context, 'Алдаа гарлаа', icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final c = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: c.copyWith(
              primary: const Color(0xFF10B981),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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
    
    // Day Stats (Filtered by selected date)
    final today = stripTime(_selectedDate);
    final todayTasks = _tasks.where((t) => t.isOnDay(today)).toList();
    final todayDone = todayTasks.where((t) => t.status == TaskStatus.completed).length;
    final todayInProgress = todayTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final todayPending = todayTasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.overdue).length;
    final todayPercent = todayTasks.isEmpty ? 0.0 : todayDone / todayTasks.length;

    // Monthly stats
    final now = TimezoneService.nowMongolia();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final monthTasks = _tasks.where((t) => t.date.isAfter(firstOfMonth.subtract(const Duration(seconds: 1)))).toList();
    final monthDone = monthTasks.where((t) => t.status == TaskStatus.completed).length;
    final monthTotal = monthTasks.length;
    final monthAttendance = monthTotal == 0 ? 0 : 100; // Simplified for now

    // Weekly Chart - Align with Monday-Sunday week
    final currentWeekDay = now.weekday; // 1 (Mon) to 7 (Sun)
    final monday = stripTime(now.subtract(Duration(days: currentWeekDay - 1)));
    
    final weekData = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _tasks.where((t) {
        if (t.status != TaskStatus.completed) return false;
        final finishDate = t.completedAt ?? t.ekhlekhOgnoo ?? t.ekhlekhTsag ?? t.date;
        return stripTime(finishDate) == day;
      }).length.toDouble();
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

    // Photo Verification Rate
    final tasksWithPhotos = _tasks.where((t) => t.hasPhoto).length;
    final photoRate = _tasks.isEmpty ? 0 : (tasksWithPhotos / _tasks.length * 100).round();

    // Area Coverage - group by task title
    final areaMap = <String, List<CleaningTask>>{};
    for (final t in _tasks) {
      if (t.title.isNotEmpty) {
        areaMap.putIfAbsent(t.title, () => []).add(t);
      }
    }
    final sortedAreas = areaMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topAreas = sortedAreas.take(4).toList();

    // Rating from KPI service
    final derivedRating = _kpi?['kpiDundaj']?.toDouble() ?? 0.0;
    final totalRatedTasks = _kpi?['kpiDaalgavarToo'] ?? 0;
    final kpiHuvv = _kpi?['kpiHuvv'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Гүйцэтгэл',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.rFontSize(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _selectDate(context),
            tooltip: 'Өдөр сонгох',
          ),
          if (_refreshingKpi)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshKpi,
              tooltip: 'Шинэчлэх',
            ),
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stripTime(_selectedDate) == stripTime(TimezoneService.nowMongolia()) 
                    ? 'Өнөөдрийн гүйцэтгэл' 
                    : '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} гүйцэтгэл',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w600)),
              ],
            ),
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
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Нийт оноо',
              value: (_kpi?['kpiOnoo'] ?? 0).toString(),
              unit: 'оноо',
              subtitle: 'Нийт цуглуулсан',
            )),
            const SizedBox(width: 12),
            Expanded(child: _InfoCard(c: c,
              icon: Icons.star_rounded,
              iconColor: c.brandGreen,
              title: 'Дунжаж оноо',
              value: derivedRating.toStringAsFixed(1),
              unit: '/ 10',
              subtitle: '$totalRatedTasks үнэлгээнээс',
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
                      c.brandGreen, now.weekday - 1, c.mutedForeground))),
              bottom: Text('Нийт: ${_tasks.length} даалгавар',
                  style: TextStyle(fontSize: 14,
                      color: c.mutedForeground))),
          const SizedBox(height: 16),

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
              title: 'Ажилууд',
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
              bottom: Text('Нийт: $monthDone/$monthTotal ажил гүйцэтгэсэн',
                  style: TextStyle(fontSize: 14,
                      color: c.mutedForeground))),
          const SizedBox(height: 16),

          const SizedBox(height: 24),
        ]),
      ),
    );
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

// Custom painters (Lines 782+)

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
    if (mx == 0) {
      final bw = sz.width / (vals.length * 2 + 1), sp = bw;
      for (int i = 0; i < vals.length; i++) {
        final x = sp+i*(bw+sp);
        cv.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h-4, bw, 4), const Radius.circular(6)),
            Paint()..color = clr.withOpacity(0.1));
        final lp = TextPainter(text: TextSpan(text: lbls[i],
            style: TextStyle(fontSize: 10, color: mutedClr, fontWeight: FontWeight.normal)),
            textDirection: TextDirection.ltr)..layout();
        lp.paint(cv, Offset(x+(bw-lp.width)/2, h+6));
      }
      return;
    }
    final bw = sz.width / (vals.length * 2 + 1), sp = bw;
    for (int i = 0; i < vals.length; i++) {
      double bh = (vals[i]/mx)*h;
      if (bh < 4) bh = 4;
      final x = sp+i*(bw+sp), y = h-bh;
      final hl = i == hi;
      cv.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, bh), const Radius.circular(6)),
          Paint()..color = hl ? clr : clr.withOpacity(0.3));
      if (hl && vals[i] > 0) {
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
