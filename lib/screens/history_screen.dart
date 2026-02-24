import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = generateMockTasks()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Даалгаврын түүх',
          style: TextStyle(fontWeight: FontWeight.w600))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final t = tasks[i];
          return ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: c.muted,
            leading: CircleAvatar(
              backgroundColor: c.brandGreen.withOpacity(0.1),
              child: Icon(t.status == TaskStatus.completed
                  ? Icons.check : Icons.schedule,
                  color: c.brandGreen)),
            title: Text(t.title, style: TextStyle(color: c.primary)),
            subtitle: Text('${t.location}\n${_fmt(t.date)}',
                style: TextStyle(color: c.mutedForeground)),
            isThreeLine: true,
            trailing: Icon(
              t.hasPhoto ? Icons.verified_rounded : Icons.photo_outlined,
              color: t.hasPhoto ? c.success : c.border),
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
