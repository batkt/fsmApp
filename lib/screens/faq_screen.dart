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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: c.brandGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Түгээмэл асуулт хариулт',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: c.mutedForeground,
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Асуултаа хайх...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: c.muted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.brandGreen),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.brandGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: c.brandGreen,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Тусламж хэрэгтэй байна уу?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: c.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Доорх асуултууд танд туслах болно',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: c.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FAQ Items (filtered)
                  ...filteredItems.map(
                    (item) => _FAQItem(
                      question: item['question']!,
                      answer: item['answer']!,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: c.brandGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Нэмэлт тусламж',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Хэрэв таны асуулт энд байхгүй бол, дэмжлэгийн багтайгаа холбогдоорой.',
                          style: TextStyle(
                            fontSize: 14,
                            color: c.mutedForeground,
                            height: 1.5,
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
