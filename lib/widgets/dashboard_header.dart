import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'project_selector.dart';

class DashboardHeader extends StatelessWidget {
  final ProjectSelector projectSelector;

  const DashboardHeader({super.key, required this.projectSelector});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сайн байна уу, ${AuthService.currentUser?.ner ?? "цэвэрлэгч"} 👋',
          style: TextStyle(
            fontSize: context.rFontSize(16),
            color: c.mutedForeground,
          ),
        ),
        context.rHeight(4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Таны хуваарь',
                style: TextStyle(
                  fontSize: context.rFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: c.primary,
                ),
              ),
            ),
            projectSelector,
          ],
        ),
      ],
    );
  }
}
