import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            'Таны гүйцэтгэлийн тойм',
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
            SizedBox(width: 150, height: 150,
              child: CustomPaint(
                painter: _RingPainter(0.75, 12,
                    Colors.white24, Colors.white),
                child: const Center(child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                  Text('75%', style: TextStyle(fontSize: 32,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('6/8 даалгавар', style: TextStyle(
                      fontSize: 14, color: Colors.white70)),
                ])))),
            const SizedBox(height: 16),
            const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              _Mini(Icons.check_circle_outline, 'Дууссан', '6'),
              _Mini(Icons.timelapse, 'Явагдаж буй', '1'),
              _Mini(Icons.schedule, 'Хүлээгдэж буй', '1'),
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
              title: 'Тасралтгүй',
              value: '12',
              unit: 'хоног',
              subtitle: 'Дараалсан өдрүүд',
            )),
            const SizedBox(width: 12),
            Expanded(child: _InfoCard(c: c,
              icon: Icons.calendar_month_rounded,
              iconColor: c.brandGreen,
              title: 'Ирц',
              value: '96%',
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
                      [5,8,6,9,7,4,6],
                      ['Дав','Мяг','Лха','Пүр','Баа','Бям','Ням'],
                      c.chart2, 3, c.mutedForeground))),
              bottom: Text('Дундаж: 6.4 даалгавар/өдөр',
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
                    value: 0.82, displayVal: '24 мин',
                    expected: '30 мин', color: c.success),
                const SizedBox(height: 16),
                _ProgressBar(c: c, label: 'Хамгийн хурдан',
                    value: 0.53, displayVal: '16 мин',
                    expected: '30 мин', color: c.info),
                const SizedBox(height: 16),
                _ProgressBar(c: c, label: 'Хамгийн удаан',
                    value: 1.0, displayVal: '38 мин',
                    expected: '30 мин', color: c.warningOrange),
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
                      [72,78,85,80,88,92,90,95],
                      c.blueAccent, c.lightBlue))),
              bottom: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up, color: c.success, size: 18),
                const SizedBox(width: 4),
                Text('+5.3% өмнөх сараас',
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.success)),
              ])),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          // 6. AREA COVERAGE
          // ═══════════════════════════════════════════
          _Card(c: c, icon: Icons.map_rounded,
              iconColor: c.chart5,
              title: 'Талбайн хамрах хүрээ',
              child: Column(children: [
                _AreaRow(c: c, area: 'А цамхаг - Үүдний танхим',
                    count: 28, total: 30, color: c.success),
                const SizedBox(height: 10),
                _AreaRow(c: c, area: '5-р давхар - Оффис',
                    count: 22, total: 25, color: c.info),
                const SizedBox(height: 10),
                _AreaRow(c: c, area: '3-р давхар - Ариун цэвэр',
                    count: 30, total: 30, color: c.brandGreen),
                const SizedBox(height: 10),
                _AreaRow(c: c, area: 'Подвал - Агуулах',
                    count: 8, total: 15, color: c.warningOrange),
              ]),
              bottom: Text('Нийт: 88/100 цэвэрлэгээ',
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
                Text('4.5 / 5.0',
                    style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: c.primary)),
                const SizedBox(height: 4),
                Text('Сүүлийн 30 хоногийн дундаж',
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
                ic: c.chart4, t: 'Үнэлгээ', v: '4.8', s: '/ 5.0')),
            const SizedBox(width: 12),
            Expanded(child: _Tile(c: c, icon: Icons.access_time_filled,
                ic: c.chart3, t: 'Цагт гүйцэтгэл', v: '96%',
                s: 'цагтаа')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Tile(c: c, icon: Icons.verified_rounded,
                ic: c.success, t: 'Зураг баталгаа', v: '98%',
                s: 'батлагдсан')),
            const SizedBox(width: 12),
            Expanded(child: _Tile(c: c, icon: Icons.emoji_events_rounded,
                ic: c.chart5, t: 'Нийт даалгавар', v: '142',
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
                    desc: '10 даалгаврыг хугацаанаас өмнө дуусгасан'),
                const SizedBox(height: 10),
                _Badge(c: c, icon: Icons.auto_awesome_rounded,
                    color: c.chart4,
                    title: 'Тэргүүн цэвэрлэгч',
                    desc: '7 хоног дараалан хамгийн өндөр үнэлгээ'),
                const SizedBox(height: 10),
                _Badge(c: c, icon: Icons.camera_enhance_rounded,
                    color: c.success,
                    title: 'Зургийн мастер',
                    desc: '50 зураг дараалан баталгаажсан'),
                const SizedBox(height: 10),
                _Badge(c: c, icon: Icons.local_fire_department,
                    color: const Color(0xFFEF4444),
                    title: '10 өдрийн streak',
                    desc: '10 хоног тасралтгүй бүх даалгавар гүйцэтгэсэн'),
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
                    thisMonth: '142', lastMonth: '128',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Чанарын оноо',
                    thisMonth: '95%', lastMonth: '90%',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Дундаж хугацаа',
                    thisMonth: '24 мин', lastMonth: '28 мин',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Ирц',
                    thisMonth: '96%', lastMonth: '92%',
                    isUp: true),
                Divider(color: c.border, height: 20),
                _CompareRow(c: c, label: 'Гомдол',
                    thisMonth: '0', lastMonth: '2',
                    isUp: true),
              ])),
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
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(children: [
        Icon(
          icon,
          color: iconColor,
          size: context.rIconSize(18),
        ),
        SizedBox(width: context.rSpacing(6)),
        Text(
          title,
          style: TextStyle(
            fontSize: context.rFontSize(14),
            fontWeight: FontWeight.w600,
            color: c.primary,
          ),
        ),
      ]),
      SizedBox(height: context.rSpacing(16)),
      child,
      if (bottom != null) ...[
        SizedBox(height: context.rSpacing(10)),
        Center(child: bottom!),
      ],
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
    padding: EdgeInsets.all(context.rSpacing(12)),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(padding: EdgeInsets.all(context.rSpacing(6)),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor,
            size: context.rIconSize(18))),
      SizedBox(height: context.rSpacing(8)),
      Text(title, style: TextStyle(
          fontSize: context.rFontSize(11),
          color: c.mutedForeground)),
      SizedBox(height: context.rSpacing(2)),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(
            fontSize: context.rFontSize(20),
            fontWeight: FontWeight.bold,
            color: c.primary)),
        if (unit.isNotEmpty) ...[
          SizedBox(width: context.rSpacing(4)),
          Padding(
            padding: EdgeInsets.only(bottom: context.rSpacing(2)),
            child: Text(unit, style: TextStyle(
                fontSize: context.rFontSize(11),
                color: c.mutedForeground)),
          ),
        ],
      ]),
      SizedBox(height: context.rSpacing(2)),
      Text(subtitle, style: TextStyle(
          fontSize: context.rFontSize(11),
          color: c.mutedForeground)),
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
    padding: EdgeInsets.all(context.rSpacing(12)),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(padding: EdgeInsets.all(context.rSpacing(6)),
        decoration: BoxDecoration(color: ic.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: ic, size: context.rIconSize(18))),
      SizedBox(height: context.rSpacing(8)),
      Text(t, style: TextStyle(
          fontSize: context.rFontSize(11),
          color: c.mutedForeground)),
      SizedBox(height: context.rSpacing(2)),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(v, style: TextStyle(
            fontSize: context.rFontSize(20),
            fontWeight: FontWeight.bold,
            color: c.primary)),
        SizedBox(width: context.rSpacing(4)),
        Padding(
          padding: EdgeInsets.only(bottom: context.rSpacing(2)),
          child: Text(s, style: TextStyle(
              fontSize: context.rFontSize(11),
              color: c.mutedForeground)),
        ),
      ]),
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
      Text(label, style: TextStyle(
          fontSize: context.rFontSize(12),
          color: c.primary,
          fontWeight: FontWeight.w500)),
      const Spacer(),
      Text('$displayVal / $expected', style: TextStyle(
          fontSize: context.rFontSize(11),
          color: c.mutedForeground)),
    ]),
    const SizedBox(height: 8),
    ClipRRect(borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 6,
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
      Expanded(
        child: Text(
          area,
          style: TextStyle(
            fontSize: context.rFontSize(12),
            color: c.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Text(
        '$count/$total',
        style: TextStyle(
          fontSize: context.rFontSize(11),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ]),
    SizedBox(height: context.rSpacing(4)),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: count / total,
        minHeight: 6,
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
      padding: EdgeInsets.all(context.rSpacing(8)),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(
          val.toString(),
          style: TextStyle(
            fontSize: context.rFontSize(16),
            fontWeight: FontWeight.bold,
            color: c.primary,
          ),
        ),
        SizedBox(height: context.rSpacing(2)),
        Text(label, style: TextStyle(
            fontSize: context.rFontSize(9),
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
    Container(width: context.rIconSize(32), height: context.rIconSize(32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: context.rIconSize(18))),
    SizedBox(width: context.rSpacing(8)),
    Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title,
        style: TextStyle(
          fontSize: context.rFontSize(13),
          fontWeight: FontWeight.w600,
          color: c.primary,
        ),
      ),
      SizedBox(height: context.rSpacing(2)),
      Text(
        desc,
        style: TextStyle(
          fontSize: context.rFontSize(11),
          color: c.mutedForeground,
        ),
        maxLines: 2,
      ),
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
    Expanded(
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.rFontSize(12),
          color: c.primary,
        ),
      ),
    ),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(
        thisMonth,
        style: TextStyle(
          fontSize: context.rFontSize(14),
          fontWeight: FontWeight.bold,
          color: c.primary,
        ),
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12, color: isUp ? c.success : c.destructive),
        const SizedBox(width: 2),
        Text(lastMonth, style: TextStyle(
            fontSize: context.rFontSize(11),
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
    final mx = vals.reduce(max);
    final h = sz.height - 28;
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
