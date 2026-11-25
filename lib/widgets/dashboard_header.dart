import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'project_selector.dart';

/// Compact header: avatar + greeting on the left, project selector on the right.
class DashboardHeader extends StatelessWidget {
  final ProjectSelector projectSelector;

  const DashboardHeader({super.key, required this.projectSelector});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ner = AuthService.currentUser?.ner ?? '';
    final usag = ner.isNotEmpty ? ner.characters.first.toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: context.rSpacing(42),
          height: context.rSpacing(42),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5B8DEF), Color(0xFF315BB0)],
            ),
          ),
          child: Text(
            usag,
            style: TextStyle(fontSize: context.rFontSize(17), fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
        context.rWidth(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сайн байна уу 👋',
                  style: TextStyle(fontSize: context.rFontSize(12.5), color: c.mutedForeground)),
              Text(
                ner.isEmpty ? 'Ажилтан' : ner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.rFontSize(16), fontWeight: FontWeight.w500, color: c.primary),
              ),
            ],
          ),
        ),
        context.rWidth(8),
        Flexible(child: projectSelector),
      ],
    );
  }
}
