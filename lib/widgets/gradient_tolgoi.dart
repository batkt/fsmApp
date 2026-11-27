import 'package:flutter/material.dart';

import 'medegdel_khonkh.dart';

/// Нүүр хуудасны толгойтой ижил загвартай бүх хуудасны толгой:
/// алтлаг градиент, доод булан бөөрөнхий, чимэглэлийн тойргууд,
/// буцах товч (шаардлагатай үед), цагаан гарчиг + дэд гарчиг, үйлдлүүд, мэдэгдлийн хонх.
///
/// `Scaffold.appBar`-д шууд өгнө: `appBar: GradientTolgoi(garchig: 'Цалин')`.
class GradientTolgoi extends StatelessWidget implements PreferredSizeWidget {
  const GradientTolgoi({
    super.key,
    required this.garchig,
    this.garchigWidget,
    this.dedGarchig,
    this.uildluud = const [],
    this.khonkh = true,
    this.butsakh,
    this.onButsakh,
    this.dood,
    this.doodUndur = 0,
  });

  final String garchig;

  /// Гарчгийн оронд өөр widget (жишээ нь лого + текст)
  final Widget? garchigWidget;
  final String? dedGarchig;

  /// Баруун талын үйлдлүүд — `GradientTolgoi.tovch(...)`-оор үүсгэвэл нэг загвартай
  final List<Widget> uildluud;

  /// Мэдэгдлийн хонх харуулах эсэх
  final bool khonkh;

  /// null бол Navigator буцах боломжтой үед автоматаар харагдана
  final bool? butsakh;
  final VoidCallback? onButsakh;

  /// Гарчгийн доор нэмэлт мөр (сегмент, огноо гэх мэт)
  final Widget? dood;
  final double doodUndur;

  static const brand = Color(0xFFF18F02);
  static const _ungunuud = [Color(0xFFF6B003), brand, Color(0xFFE67E00)];

  @override
  Size get preferredSize => Size.fromHeight(74 + (dood != null ? doodUndur + 10 : 0));

  /// Толгой дээрх дугуй цагаан-тунгалаг icon товч
  static Widget tovch({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tailbar,
    Key? key,
  }) {
    return IconButton(
      key: key,
      tooltip: tailbar,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        fixedSize: const Size(42, 42),
      ),
      icon: Icon(icon, size: 21, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deedZai = MediaQuery.paddingOf(context).top;
    final butsakhKharagdakh = butsakh ?? Navigator.of(context).canPop();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _ungunuud,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(children: [
        const Positioned(right: -40, top: -30, child: _Toirog(150, 0.10)),
        const Positioned(left: -30, bottom: -60, child: _Toirog(110, 0.07)),
        Padding(
          padding: EdgeInsets.fromLTRB(butsakhKharagdakh ? 10 : 20, deedZai + 10, 14, 14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 50,
              child: Row(children: [
                if (butsakhKharagdakh) ...[
                  tovch(
                    icon: Icons.arrow_back_rounded,
                    tailbar: 'Буцах',
                    onPressed: onButsakh ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dedGarchig != null)
                          Text(
                            dedGarchig!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: Color(0xD9FFFFFF)),
                          ),
                        garchigWidget ??
                            Text(garchig, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                for (final u in uildluud) ...[const SizedBox(width: 6), u],
                if (khonkh) ...[const SizedBox(width: 6), const MedegdelKhonkh(tsagaanDeer: false)],
              ]),
            ),
            if (dood != null) ...[
              const SizedBox(height: 10),
              SizedBox(height: doodUndur, child: dood),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Toirog extends StatelessWidget {
  const _Toirog(this.khemjee, this.tunguu);
  final double khemjee;
  final double tunguu;

  @override
  Widget build(BuildContext context) => Container(
        width: khemjee,
        height: khemjee,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: tunguu)),
      );
}
