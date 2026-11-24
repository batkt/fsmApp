import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/irts_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

const _emerald = Color(0xFF059669);

/// Хонхонд харагдах нэг мэдэгдэл (эх сурвалжаас үл хамааран)
class _Medegdel {
  _Medegdel({
    required this.id,
    required this.ekh,
    required this.title,
    required this.message,
    required this.ognoo,
    required this.unshsan,
    this.tuluv,
  });
  final String id;
  /// fsm | irtsMinii | irtsAdmin
  final String ekh;
  final String title;
  final String message;
  final DateTime? ognoo;
  bool unshsan;
  /// Хүсэлтийн шийдвэр бол zuvshurulusen | tatgalzsan
  final String? tuluv;
}

/// Мэдэгдлийн хонх: уншаагүйн тоотой улаан тэмдэг, дарвал бүх мэдэгдэл.
/// Эх сурвалж: FSM-ийн мэдэгдэл (FSM хэрэглэгч), ирцийн хүсэлтийн шийдвэр
/// (бүх хэрэглэгч), irts-ийн удирдлагын мэдэгдэл (irts Admin).
class MedegdelKhonkh extends StatefulWidget {
  const MedegdelKhonkh({super.key, this.tsagaanDeer = true});
  /// Цагаан дугуй дэвсгэртэй (газрын зураг дээр); false бол өнгөт толгой дээр
  final bool tsagaanDeer;
  @override
  State<MedegdelKhonkh> createState() => _MedegdelKhonkhState();
}

class _MedegdelKhonkhState extends State<MedegdelKhonkh> {
  int _unshaagui = 0;
  Timer? _timer;

  bool get _irts => AuthService.currentUser?.irtsEsekh ?? false;
  bool get _admin => AuthService.currentUser?.role == 'Admin';

  @override
  void initState() {
    super.initState();
    _toogoo();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _toogoo());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<int> _safe(Future<int> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _toogoo() async {
    final toonuud = await Future.wait([
      _safe(() async => (await IrtsService.miniiMedegdluud()).$2),
      if (_irts && _admin) _safe(() async => (await IrtsService.medegdluud()).$2),
      if (!_irts) _safe(NotificationService.myUnreadCount),
    ]);
    if (mounted) setState(() => _unshaagui = toonuud.fold(0, (a, b) => a + b));
  }

  Future<List<_Medegdel>> _bugdiigAvya() async {
    final list = <_Medegdel>[];
    Future<void> safe(Future<void> Function() f) async {
      try {
        await f();
      } catch (_) {}
    }

    DateTime? ognoo(dynamic v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

    await Future.wait([
      safe(() async {
        for (final m in (await IrtsService.miniiMedegdluud()).$1) {
          list.add(_Medegdel(
            id: m['_id'].toString(),
            ekh: 'irtsMinii',
            title: m['title']?.toString() ?? 'Мэдэгдэл',
            message: m['message']?.toString() ?? '',
            ognoo: ognoo(m['createdAt']),
            unshsan: m['unshsan'] == true,
            tuluv: m['tuluv']?.toString(),
          ));
        }
      }),
      if (_irts && _admin)
        safe(() async {
          for (final m in (await IrtsService.medegdluud()).$1) {
            list.add(_Medegdel(
              id: m['_id'].toString(),
              ekh: 'irtsAdmin',
              title: m['title']?.toString() ?? 'Мэдэгдэл',
              message: m['message']?.toString() ?? '',
              ognoo: ognoo(m['createdAt']),
              unshsan: m['unshsan'] == true,
            ));
          }
        }),
      if (!_irts)
        safe(() async {
          for (final n in await NotificationService.myNotifications()) {
            list.add(_Medegdel(
              id: n.id,
              ekh: 'fsm',
              title: n.title,
              message: n.message,
              ognoo: n.createdAt.toLocal(),
              unshsan: n.kharsanEsekh || n.tuluv == 1,
            ));
          }
        }),
    ]);
    list.sort((a, b) => (b.ognoo ?? DateTime(2000)).compareTo(a.ognoo ?? DateTime(2000)));
    return list;
  }

  Future<void> _unshsan(_Medegdel m) async {
    switch (m.ekh) {
      case 'irtsMinii':
        await IrtsService.miniiMedegdelUnshsan(id: m.id);
      case 'irtsAdmin':
        await IrtsService.medegdelUnshsan(m.id);
      default:
        await NotificationService.markAsRead(m.id);
    }
  }

  Future<void> _bugdUnshsan(List<_Medegdel> list) async {
    final user = AuthService.currentUser;
    await Future.wait([
      if (list.any((m) => m.ekh == 'irtsMinii' && !m.unshsan)) IrtsService.miniiMedegdelUnshsan().catchError((_) {}),
      for (final m in list.where((m) => m.ekh == 'irtsAdmin' && !m.unshsan)) IrtsService.medegdelUnshsan(m.id).catchError((_) {}),
      if (user != null && list.any((m) => m.ekh == 'fsm' && !m.unshsan))
        NotificationService.markAllAsRead(ajiltniiId: user.id, baiguullagiinId: user.baiguullagaId).then((_) {}).catchError((_) {}),
    ]);
  }

  Future<void> _neey() async {
    final list = await _bugdiigAvya();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _MedegdliinJagsaalt(jagsaalt: list, onUnshsan: _unshsan, onBugdUnshsan: _bugdUnshsan),
    );
    _toogoo();
  }

  @override
  Widget build(BuildContext context) {
    final too = _unshaagui > 99 ? '99+' : '$_unshaagui';
    return IconButton(
      tooltip: _unshaagui > 0 ? 'Мэдэгдэл, $_unshaagui уншаагүй' : 'Мэдэгдэл',
      onPressed: _neey,
      style: IconButton.styleFrom(
        backgroundColor: widget.tsagaanDeer ? Colors.white : Colors.white.withValues(alpha: 0.2),
      ),
      icon: Stack(clipBehavior: Clip.none, children: [
        Icon(Icons.notifications_none_rounded, size: 22, color: widget.tsagaanDeer ? _emerald : Colors.white),
        if (_unshaagui > 0)
          Positioned(
            right: -7,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17),
              height: 17,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(too, style: const TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
      ]),
    );
  }
}

class _MedegdliinJagsaalt extends StatefulWidget {
  const _MedegdliinJagsaalt({required this.jagsaalt, required this.onUnshsan, required this.onBugdUnshsan});
  final List<_Medegdel> jagsaalt;
  final Future<void> Function(_Medegdel) onUnshsan;
  final Future<void> Function(List<_Medegdel>) onBugdUnshsan;
  @override
  State<_MedegdliinJagsaalt> createState() => _MedegdliinJagsaaltState();
}

class _MedegdliinJagsaaltState extends State<_MedegdliinJagsaalt> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = widget.jagsaalt;
    final unshaagui = list.where((m) => !m.unshsan).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, sc) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
          child: Row(children: [
            Expanded(child: Text('Мэдэгдэл', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: c.primary))),
            if (unshaagui > 0)
              TextButton.icon(
                onPressed: () async {
                  await widget.onBugdUnshsan(list);
                  if (mounted) setState(() => list.forEach((m) => m.unshsan = true));
                },
                style: TextButton.styleFrom(foregroundColor: _emerald),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Бүгдийг уншсан'),
              ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_off_outlined, size: 48, color: c.mutedForeground.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('Мэдэгдэл алга', style: TextStyle(fontSize: 15, color: c.mutedForeground)),
                  ]),
                )
              : ListView.separated(
                  controller: sc,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final (ikon, ungu) = switch (m.tuluv) {
                      'zuvshurulusen' => (Icons.check_circle_rounded, _emerald),
                      'tatgalzsan' => (Icons.cancel_rounded, const Color(0xFFDC2626)),
                      _ => (Icons.notifications_none_rounded, _emerald),
                    };
                    return ListTile(
                      tileColor: m.unshsan ? null : _emerald.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: CircleAvatar(backgroundColor: ungu.withValues(alpha: 0.12), child: Icon(ikon, color: ungu)),
                      title: Text(m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: m.unshsan ? FontWeight.w500 : FontWeight.w500, color: c.primary)),
                      subtitle: Text(m.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.mutedForeground)),
                      trailing: m.ognoo == null
                          ? null
                          : Text('${m.ognoo!.month.toString().padLeft(2, '0')}.${m.ognoo!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                      onTap: () async {
                        if (m.unshsan) return;
                        try {
                          await widget.onUnshsan(m);
                        } catch (_) {}
                        if (mounted) setState(() => m.unshsan = true);
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
