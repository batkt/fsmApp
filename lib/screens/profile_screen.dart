import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Профайл',
          style: TextStyle(fontWeight: FontWeight.w600))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 32,
                backgroundColor: c.brandGreen.withOpacity(0.1),
                child: Icon(Icons.person, size: 32,
                    color: c.brandGreen)),
            const SizedBox(height: 16),
            Text('Цэвэрлэгчийн нэр', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold, color: c.primary)),
            const SizedBox(height: 4),
            Text('Өнөөдрийн гүйцэтгэлийн тойм',
                style: TextStyle(fontSize: 13,
                    color: c.mutedForeground)),
            const SizedBox(height: 24),
            Row(children: [
              _Card(label: 'Дууссан', value: '3', color: c.success),
              const SizedBox(width: 12),
              _Card(label: 'Явагдаж буй', value: '1', color: c.info),
            ]),
            const SizedBox(height: 24),
            Text('Энэ хуудас нь профайл/тохиргооны дэлгэрэнгүй мэдээллийн хуудас юм.',
                style: TextStyle(color: c.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value,
      required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(value, style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12,
              color: c.mutedForeground)),
        ]),
      ),
    );
  }
}
