import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Filter FAQ items by search query
    final lowerQuery = _query.toLowerCase();
    final filteredItems = lowerQuery.isEmpty
        ? _faqItems
        : _faqItems.where((item) {
            final q = item['question']!.toLowerCase();
            final a = item['answer']!.toLowerCase();
            return q.contains(lowerQuery) || a.contains(lowerQuery);
          }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: c.brandGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Тусламж',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: c.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.muted.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                    color: c.mutedForeground,
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                style: TextStyle(fontSize: 15, color: c.primary),
                decoration: InputDecoration(
                  hintText: 'Асуултаа хайх...',
                  hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.search_rounded, color: c.brandGreen, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: c.secondary.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.brandGreen.withOpacity(0.5), width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),

            // Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          c.brandGreen.withOpacity(0.15),
                          c.brandGreen.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.brandGreen.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сайн байна уу? 👋',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.brandGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Танд ямар тусламж хэрэгтэй байна вэ? Бид таны асуултанд хариулахад бэлэн байна.',
                          style: TextStyle(
                            fontSize: 14,
                            color: c.primary.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'ТҮГЭЭМЭЛ АСУУЛТУУД',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.mutedForeground,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FAQ Items (filtered)
                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: c.muted.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'Илэрц олдсонгүй',
                              style: TextStyle(color: c.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map(
                      (item) => _FAQItem(
                        question: item['question']!,
                        answer: item['answer']!,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Contact section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Бусад асуулт',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Хэрэв та өөрийн хайж буй хариултыг олж чадаагүй бол манай тусламжийн багтай холбогдоно уу.',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              foregroundColor: c.background,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Холбоо барих',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: safeAreaBottom > 0 ? safeAreaBottom : 20),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, String>> _faqItems = [
    {
      'question': 'Даалгаврыг хэрхэн эхлүүлэх вэ?',
      'answer':
          'Даалгаврын дэлгэрэнгүй цонх нээгдэхэд "Эхлэх" товч дээр дараад даалгаврыг эхлүүлнэ. Даалгавар эхлэхэд статус нь "Явагдаж буй" болж өөрчлөгдөнө.',
    },
    {
      'question': 'Даалгаврыг хэрхэн дуусгах вэ?',
      'answer':
          'Даалгаврыг дуусгахын тулд даалгаврын дэлгэрэнгүй цонхноос "Дуусгах" товч дээр дараарай. Бүх дэд даалгаврууд дууссан эсэхийг шалгаарай.',
    },
    {
      'question': 'Зураг хэрхэн нэмэх вэ?',
      'answer':
          'Даалгаврын дэлгэрэнгүй цонхноос "Зураг" хэсэгт байрлах "Нэмэх" товч дээр дараад камер нээгдэнэ. Зураг аваад хадгална уу.',
    },
    {
      'question': 'Дэд даалгаврыг хэрхэн тэмдэглэх вэ?',
      'answer':
          'Дэд даалгаврын жагсаалтаас тэмдэглэх дэд даалгавар дээр дараад тэмдэглэгдэнэ. Тэмдэглэгдсэн дэд даалгаврууд ногоон өнгөтэй болж, зураасаар тэмдэглэгдэнэ.',
    },
    {
      'question': 'Мэдэгдлүүдийг хэрхэн унших вэ?',
      'answer':
          'Дээд баруун буланд байрлах мэдэгдлийн дүрс дээр дараад мэдэгдлийн цонх нээгдэнэ. Мэдэгдэл дээр дараад уншсан болгох эсвэл "Бүгд уншсан" товч дээр дараад бүх мэдэгдлийг уншсан болгох боломжтой.',
    },
    {
      'question': 'Төслийг хэрхэн сонгох вэ?',
      'answer':
          'Хяналтын самбарын дээд хэсэгт байрлах төслийн сонголтын товч дээр дараад хүссэн төслөө сонгоно уу.',
    },
    {
      'question': 'Календарыг хэрхэн ашиглах вэ?',
      'answer':
          'Календарын өдөр дээр дараад тухайн өдрийн даалгавруудыг харах боломжтой. Долоо хоног шударч өмнөх/дараагийн долоо хоног руу шилжих боломжтой.',
    },
    {
      'question': 'Чат хэрхэн ашиглах вэ?',
      'answer':
          'Даалгаврын карт дээр байрлах чат дүрс дээр дараад даалгаврын чат цонх нээгдэнэ. Эндээс бусад ажилтнуудтай мессеж солилцох боломжтой.',
    },
    {
      'question': 'Даалгаврыг хэрхэн шүүх вэ?',
      'answer':
          'Хяналтын самбарын шүүлтийн товчнуудыг ашиглан даалгавруудыг статусаар нь шүүж харах боломжтой: "Бүгд", "Хүлээгдэж буй", "Явагдаж буй", "Дууссан".',
    },
    {
      'question': 'Заавар хэрхэн ажиллуулах вэ?',
      'answer':
          'Дээд баруун буланд байрлах тусламжийн дүрс (?) дээр дараад заавар эхлэнэ. Заавар нь бүх үндсэн функцүүдийг тайлбарлана.',
    },
  ];
}

class _FAQItem extends StatefulWidget {
  const _FAQItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: c.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: c.mutedForeground,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
