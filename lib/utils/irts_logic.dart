// Ирцийн товчны төлөв — irtsWeb pages/khyanalt/irts/irtsqr/index.js-ийн
// buttonState, utils/irtsPeriods.js (chuluundGarsanChuluu,
// chuluunaasButsaakhEsekh)-ийн Dart хувилбар. Дүрэм өөрчлөгдвөл хоёуланг нь засна.

import 'package:flutter/material.dart';

enum IrtsUildel { orokh, chuluunaasOrokh, tsainiiGarakh, tsainiiOrokh, garakh, garakhHulee, khuleekh, duussan, amralt }

extension IrtsUildelNer on IrtsUildel {
  /// Товч дээрх үйлдэл (хийх гэж буй зүйл)
  String get tovch => switch (this) {
        IrtsUildel.orokh => 'Орох',
        IrtsUildel.chuluunaasOrokh => 'Чөлөөнөөс орох',
        IrtsUildel.tsainiiGarakh => 'Цайнд гарах',
        IrtsUildel.tsainiiOrokh => 'Цайнаас орох',
        IrtsUildel.garakh => 'Гарах',
        IrtsUildel.garakhHulee => 'Гарах',
        IrtsUildel.khuleekh => 'Хүлээнэ үү',
        IrtsUildel.duussan => 'Өнөөдрийн ажил дууссан',
        IrtsUildel.amralt => 'Өнөөдөр амралттай',
      };

  /// Бүртгэгдсэний дараах мэдэгдэл
  String get burtgesen => switch (this) {
        IrtsUildel.orokh => 'Ирлээ',
        IrtsUildel.chuluunaasOrokh => 'Чөлөөнөөс орлоо',
        IrtsUildel.tsainiiGarakh => 'Цайнд гарлаа',
        IrtsUildel.tsainiiOrokh => 'Цайнаас орлоо',
        _ => 'Гарлаа',
      };

  /// Backend-д илгээх turul
  String? get turul => switch (this) {
        IrtsUildel.orokh => 'orokh',
        IrtsUildel.chuluunaasOrokh => 'chuluunaasOrokh',
        IrtsUildel.tsainiiGarakh => 'tsainiiGarakh',
        IrtsUildel.tsainiiOrokh => 'tsainiiOrokh',
        IrtsUildel.garakh => 'garakh',
        _ => null,
      };
}

DateTime? ognooUnshikh(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<Map> asArray(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.whereType<Map>().toList();
  if (v is Map) return [v];
  return const [];
}

/// "HH:mm" → өнөөдрийн DateTime
DateTime? tsagiigOgnoo(String? t, [DateTime? udur]) {
  if (t == null || !t.contains(':')) return null;
  final p = t.split(':');
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  if (h == null) return null;
  final d = udur ?? DateTime.now();
  return DateTime(d.year, d.month, d.day, h, m ?? 0);
}

/// Тухайн гарагийн хуваарь (barilga.ajillakhUdruud)
Map? odriinKhuvaari(Map? barilga, DateTime udur) {
  final garag = (udur.weekday % 7).toString(); // JS getDay(): Ням = 0
  for (final x in asArray(barilga?['ajillakhUdruud'])) {
    final udruud = (x['udruud'] as List? ?? []).map((e) => e.toString());
    if (udruud.contains(garag)) return x;
  }
  return null;
}

Map? chuluundGarsanChuluu(Map? mur, DateTime? khaakh) {
  final irsen = ognooUnshikh(mur?['irsenTsag']);
  final yawsan = ognooUnshikh(mur?['yawsanTsag']);
  if (irsen == null || yawsan == null) return null;
  if (khaakh != null && !yawsan.isBefore(khaakh)) return null;
  for (final u in asArray(mur?['chuluuniiTurul'])) {
    final ekh = ognooUnshikh(u['ekhlekhOgnoo']);
    final tug = ognooUnshikh(u['duusakhOgnoo']);
    if (ekh == null || tug == null || u['orsonTsag'] != null) continue;
    if ((khaakh == null || tug.isBefore(khaakh)) &&
        yawsan.isBefore(tug) &&
        !yawsan.isBefore(ekh.subtract(const Duration(minutes: 30)))) {
      return u;
    }
  }
  return null;
}

bool chuluunaasButsaakhEsekh(Map? mur, DateTime? khaakh, DateTime odoo) {
  final irsen = ognooUnshikh(mur?['irsenTsag']);
  if (irsen == null || mur?['yawsanTsag'] != null) return false;
  if (khaakh != null && !odoo.isBefore(khaakh)) return false;
  Map? suuliin;
  for (final u in asArray(mur?['chuluuniiTurul'])) {
    final ekh = ognooUnshikh(u['ekhlekhOgnoo']);
    final tug = ognooUnshikh(u['duusakhOgnoo']);
    if (ekh == null || tug == null) continue;
    if (!ekh.isAfter(odoo) && odoo.isBefore(tug)) return false;
    if (!tug.isAfter(odoo) &&
        (suuliin == null || tug.isAfter(ognooUnshikh(suuliin['duusakhOgnoo'])!))) {
      suuliin = u;
    }
  }
  if (suuliin == null || suuliin['orsonTsag'] != null) return false;
  if (!ognooUnshikh(suuliin['ekhlekhOgnoo'])!.isAfter(irsen)) return false;
  return khaakh == null || ognooUnshikh(suuliin['duusakhOgnoo'])!.isBefore(khaakh);
}

/// Одоо дарах ёстой товч
IrtsUildel irtsiinUildel({required Map? irts, required Map? barilga, DateTime? odoo}) {
  final now = odoo ?? DateTime.now();
  final tsag = odriinKhuvaari(barilga, now);
  final tokhirgoo = barilga?['tokhirgoo'] as Map? ?? const {};
  final tsaiAshiglakh = tokhirgoo['tsainiiTsagAshiglakhEsekh'] ?? true;
  final tsaiDaraaMinut = (tokhirgoo['tsainiiDuurssanaasGarakhMinut'] as num?)?.toInt() ?? 0;

  // Хуваарьгүй өдөр JS-ийн setTime(undefined)-тэй адил өнөөдрийн одоогийн
  // цагийг өөрчлөхгүй үлдээдэг тул энд одоогийн цагийг ашиглана
  final tsaiEkh = tsagiigOgnoo(tsag?['tsainiiNeekhTsag'], now) ?? now;
  final tsaiTug = tsagiigOgnoo(tsag?['tsainiiKhaakhTsag'], now) ?? now;
  final khaakh = tsagiigOgnoo(tsag?['khaakhTsag'], now) ?? now;

  if (irts?['amralt'] != null || irts?['tuluv'] == 'amralt') return IrtsUildel.amralt;

  final irsen = irts?['irsenTsag'] != null;
  final yawsan = irts?['yawsanTsag'] != null;
  final tsaiGarsan = irts?['tsainiiGarsanTsag'] != null;
  final tsaiIrsen = irts?['tsainiiIrsenTsag'] != null;

  if (yawsan) {
    if (now.isBefore(khaakh) && chuluundGarsanChuluu(irts, khaakh) != null) {
      return IrtsUildel.chuluunaasOrokh;
    }
    return IrtsUildel.duussan;
  }
  if (!irsen) return now.isBefore(khaakh) ? IrtsUildel.orokh : IrtsUildel.garakh;

  if (!(tsaiGarsan && !tsaiIrsen) && chuluunaasButsaakhEsekh(irts, khaakh, now)) {
    return IrtsUildel.chuluunaasOrokh;
  }

  final tsaiAlgassan = !tsaiGarsan && !now.isBefore(tsaiTug);
  if (!tsaiAlgassan && !now.isBefore(tsaiEkh) && !tsaiIrsen) {
    if (!now.isBefore(khaakh)) return IrtsUildel.garakh;
    if (!tsaiGarsan) return IrtsUildel.tsainiiGarakh;
    return IrtsUildel.tsainiiOrokh;
  }
  if (!now.isBefore(khaakh)) return IrtsUildel.garakh;

  final garakhBoloomjtoi =
      tsaiDaraaMinut > 0 ? tsaiTug.add(Duration(minutes: tsaiDaraaMinut)) : null;
  if (tsaiAshiglakh == true &&
      garakhBoloomjtoi != null &&
      !now.isBefore(tsaiTug) &&
      now.isBefore(garakhBoloomjtoi)) {
    return IrtsUildel.garakhHulee;
  }
  return IrtsUildel.garakh;
}

// ── Төлөвийн өнгө ──

class IrtsTuluv {
  const IrtsTuluv(this.ner, this.ungu);
  final String ner;
  final Color ungu;
}

const irtsTuluvuud = <String, IrtsTuluv>{
  'kheviin': IrtsTuluv('Ирсэн', Color(0xFF10B981)),
  'khotsorson': IrtsTuluv('Хоцорсон', Color(0xFFF59E0B)),
  'hagas': IrtsTuluv('Хагас', Color(0xFFFB923C)),
  'chuluu': IrtsTuluv('Чөлөөтэй', Color(0xFF0EA5E9)),
  'amralt': IrtsTuluv('Амралт', Color(0xFF8B5CF6)),
  'tasalsan': IrtsTuluv('Тасалсан', Color(0xFFF43F5E)),
};

/// Хадгалагдсан төлөв (backend тооцсон); хоосон бол зөвхөн ирсэн эсэх
String? bichlegiinTuluv(Map? irts) {
  if (irts == null) return null;
  final t = irts['tuluv']?.toString();
  if (t != null && irtsTuluvuud.containsKey(t)) return t;
  return irts['irsenTsag'] != null ? 'kheviin' : null;
}

// ── Сарын нэгтгэл (Нүүр хуудас, Ирцийн тайланд) ──

class SarynDun {
  SarynDun({
    required this.khuvaart,
    required this.ajillasan,
    required this.khotsorson,
    required this.ertTarsan,
    required this.iluu,
    required this.irsenUdur,
    required this.tasalsanUdur,
    required this.ajlynUdur,
  });

  /// Хуваарьт ажиллах ёстой минут (сарын бүх ажлын өдөр)
  final int khuvaart;
  /// Ажилласан минут (backend-ийн ajillasanMinut)
  final int ajillasan;
  final int khotsorson;
  final int ertTarsan;
  final int iluu;
  final int irsenUdur;
  final int tasalsanUdur;
  final int ajlynUdur;

  int get uldsen => (khuvaart - ajillasan).clamp(0, 1 << 30);
  double get khuvi => khuvaart == 0 ? 0 : (ajillasan / khuvaart).clamp(0.0, 1.0);
}

int _tsagMinut(String? t) {
  if (t == null || !t.contains(':')) return 0;
  final p = t.split(':');
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

/// Нэг өдрийн хуваарьт минут (цайны цагийг хасна)
int odriinKhuvaartMinut(Map? barilga, DateTime udur) {
  final kh = odriinKhuvaari(barilga, udur);
  if (kh == null) return 0;
  var m = _tsagMinut(kh['khaakhTsag']) - _tsagMinut(kh['neekhTsag']);
  final tsaiAshiglakh = (barilga?['tokhirgoo'] as Map?)?['tsainiiTsagAshiglakhEsekh'] ?? true;
  if (tsaiAshiglakh == true) {
    m -= (_tsagMinut(kh['tsainiiKhaakhTsag']) - _tsagMinut(kh['tsainiiNeekhTsag'])).clamp(0, 600);
  }
  return m.clamp(0, 24 * 60);
}

SarynDun sarynDunTootsoo(List<Map> irtsuud, Map? barilga, DateTime sar) {
  var khuvaart = 0, ajlynUdur = 0;
  final udriinToo = DateTime(sar.year, sar.month + 1, 0).day;
  for (var d = 1; d <= udriinToo; d++) {
    final m = odriinKhuvaartMinut(barilga, DateTime(sar.year, sar.month, d));
    if (m > 0) {
      khuvaart += m;
      ajlynUdur++;
    }
  }
  int n(dynamic v) => (v as num?)?.round() ?? 0;
  var ajillasan = 0, khotsorson = 0, ertTarsan = 0, iluu = 0, irsen = 0, tasalsan = 0;
  for (final x in irtsuud) {
    ajillasan += n(x['ajillasanMinut']);
    khotsorson += n(x['khotsorsonMinut']) + n(x['khotsorsonMinutTsainiiTsag']);
    ertTarsan += n(x['khotsorsonMinutGarakh']);
    iluu += n(x['iluurCagMinut']);
    if (x['irsenTsag'] != null) irsen++;
    if (bichlegiinTuluv(x) == 'tasalsan') tasalsan++;
  }
  return SarynDun(
    khuvaart: khuvaart,
    ajillasan: ajillasan,
    khotsorson: khotsorson,
    ertTarsan: ertTarsan,
    iluu: iluu,
    irsenUdur: irsen,
    tasalsanUdur: tasalsan,
    ajlynUdur: ajlynUdur,
  );
}

/// 6450 → "107ц 30м"
String tsagMinutTekst(int minut) {
  final h = minut ~/ 60, m = minut % 60;
  if (h == 0) return '$mм';
  return m == 0 ? '$hц' : '$hц $mм';
}
