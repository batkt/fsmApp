import 'dart:async';

import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_tolgoi.dart';

const _brand = Color(0xFFF18F02);
const _sanaluud = [
  'Энэ сард би хэдэн цаг ажилласан бэ?',
  'Миний хүсэлтүүд ямар төлөвтэй байна?',
  'Чөлөөний хүсэлт яаж илгээх вэ?',
  'Ирц бүртгэхэд яагаад алдаа гараад байна?',
];

/// AI туслах: ирц, хүсэлт, системийн тухай асуулт (irtsBack /aiTuslakh, Gemini).
/// Хариу хэсэг хэсгээр нь (stream) гарч ирнэ.
class AiTuslakhScreen extends StatefulWidget {
  const AiTuslakhScreen({super.key});
  @override
  State<AiTuslakhScreen> createState() => _AiTuslakhScreenState();
}

class _Messej {
  _Messej(this.role, this.content);
  final String role;
  String content;
  bool aldaa = false;
}

class _AiTuslakhScreenState extends State<AiTuslakhScreen> {
  final _messejuud = <_Messej>[];
  final _orolt = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<String>? _sub;
  bool _ajillaj = false;

  @override
  void dispose() {
    _sub?.cancel();
    _orolt.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _dooshoo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _ilgeekh([String? text]) {
    final asuult = (text ?? _orolt.text).trim();
    if (asuult.isEmpty || _ajillaj) return;
    _orolt.clear();
    final tuukh = [
      for (final m in _messejuud)
        if (!m.aldaa && m.content.isNotEmpty) {'role': m.role, 'content': m.content},
      {'role': 'user', 'content': asuult},
    ];
    final khariu = _Messej('assistant', '');
    setState(() {
      _messejuud.add(_Messej('user', asuult));
      _messejuud.add(khariu);
      _ajillaj = true;
    });
    _dooshoo();
    _sub = IrtsService.aiTuslakh(tuukh).listen(
      (heseg) {
        setState(() => khariu.content += heseg);
        _dooshoo();
      },
      onError: (e) {
        setState(() {
          khariu.content = e is IrtsAldaa ? e.message : 'Сүлжээний алдаа гарлаа. Дахин оролдоно уу.';
          khariu.aldaa = true;
          _ajillaj = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          if (khariu.content.isEmpty && !khariu.aldaa) khariu.content = 'Уучлаарай, хариу гаргаж чадсангүй.';
          _ajillaj = false;
        });
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.loginBackground,
      appBar: GradientTolgoi(
        garchig: 'AI туслах',
        khonkh: false,
        uildluud: [
          if (_messejuud.isNotEmpty)
            GradientTolgoi.tovch(
              icon: Icons.refresh_rounded,
              tailbar: 'Шинэ яриа',
              onPressed: () {
                _sub?.cancel();
                setState(() {
                  _messejuud.clear();
                  _ajillaj = false;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: _messejuud.isEmpty
                ? ListView(padding: const EdgeInsets.all(16), children: [
                    Text('Сайн байна уу! Жишээ асуултууд:', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                    const SizedBox(height: 12),
                    for (final s in _sanaluud)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Color.alphaBlend(_brand.withValues(alpha: 0.08), c.cardBackground),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _brand.withValues(alpha: 0.18)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _ilgeekh(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(s, style: TextStyle(fontSize: 14, color: c.primary)),
                            ),
                          ),
                        ),
                      ),
                  ])
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: _messejuud.length,
                    itemBuilder: (context, i) => _Bombogo(m: _messejuud[i]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: c.cardBackground,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _orolt,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _ilgeekh(),
                  decoration: InputDecoration(
                    hintText: 'Асуултаа бичнэ үү…',
                    counterText: '',
                    filled: true,
                    fillColor: c.muted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: _orolt,
                builder: (context, _) => IconButton.filled(
                  tooltip: 'Илгээх',
                  onPressed: _ajillaj || _orolt.text.trim().isEmpty ? null : _ilgeekh,
                  style: IconButton.styleFrom(backgroundColor: _brand, fixedSize: const Size(46, 46)),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bombogo extends StatelessWidget {
  const _Bombogo({required this.m});
  final _Messej m;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final minii = m.role == 'user';
    return Align(
      alignment: minii ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: minii ? const LinearGradient(colors: [Color(0xFFF6B003), _brand]) : null,
          color: minii ? null : (m.aldaa ? c.destructive.withValues(alpha: 0.1) : c.cardBackground),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(minii ? 18 : 6),
            bottomRight: Radius.circular(minii ? 6 : 18),
          ),
        ),
        child: m.content.isEmpty
            ? SizedBox(
                width: 28,
                height: 16,
                child: Center(child: LinearProgressIndicator(minHeight: 3, color: _brand, backgroundColor: c.muted)),
              )
            : SelectableText(
                m.content,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: minii ? Colors.white : (m.aldaa ? c.destructive : c.primary),
                ),
              ),
      ),
    );
  }
}
