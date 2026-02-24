import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Гүйцэтгэл',
          style: TextStyle(fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('Таны гүйцэтгэлийн тойм',
              style: TextStyle(fontSize: 16, color: c.mutedForeground)),
          const SizedBox(height: 20),

          // 1. Circular Progress
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [c.brandGreen, const Color(0xFF047857),
                    const Color(0xFF065F46)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: c.brandGreen.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              const Text('Өнөөдрийн гүйцэтгэл',
                  style: TextStyle(color: Colors.white, fontSize: 16,
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
                        fontSize: 12, color: Colors.white70)),
                  ])))),
              const SizedBox(height: 16),
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                _Mini(Icons.check_circle_outline, 'Дууссан', '6'),
                _Mini(Icons.timelapse, 'Явагдаж буй', '1'),
                _Mini(Icons.schedule, 'Хүлээгдэж буй', '1'),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // 2. Bar Chart
          _Card(c: c, icon: Icons.bar_chart_rounded,
              iconColor: c.chart1, title: '7 хоногийн гүйцэтгэл',
              child: SizedBox(height: 160,
                child: CustomPaint(size: const Size(double.infinity, 160),
                    painter: _BarsPainter(
                      [5,8,6,9,7,4,6],
                      ['Дав','Мяг','Лха','Пүр','Баа','Бям','Ням'],
                      c.chart2, 3, c.mutedForeground))),
              bottom: Text('Дундаж: 6.4 даалгавар/өдөр',
                  style: TextStyle(fontSize: 12,
                      color: c.mutedForeground))),
          const SizedBox(height: 20),

          // 3. Line Chart
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
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500, color: c.success)),
              ])),
          const SizedBox(height: 20),

          // 4. Stats
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
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.label, this.value);
  final IconData icon; final String label, value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.white70, size: 20),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 18,
        fontWeight: FontWeight.bold, color: Colors.white)),
    Text(label, style: const TextStyle(fontSize: 10,
        color: Colors.white70)),
  ]);
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
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w600, color: c.primary)),
      ]),
      const SizedBox(height: 20),
      child,
      if (bottom != null) ...[
        const SizedBox(height: 12),
        Center(child: bottom!),
      ],
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.border),
      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: ic.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: ic, size: 20)),
      const SizedBox(height: 12),
      Text(t, style: TextStyle(fontSize: 11, color: c.mutedForeground)),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(v, style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: c.primary)),
        const SizedBox(width: 4),
        Padding(padding: const EdgeInsets.only(bottom: 3),
          child: Text(s, style: TextStyle(fontSize: 11,
              color: c.mutedForeground))),
      ]),
    ]),
  );
}

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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: lc)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, Offset(pts.last.dx-tp.width-8, pts.last.dy-6));
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
