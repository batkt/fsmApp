import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class TaskProgressBar extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const TaskProgressBar({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final c = context.colors;
    return Container(
      padding: context.rPadding(all: 14),
      decoration: BoxDecoration(
        color: c.brandGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(context.rRadius(14)),
        border: Border.all(color: c.brandGreen.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pie_chart_rounded,
            size: context.rIconSize(20),
            color: c.brandGreen,
          ),
          context.rWidth(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Өнөөдрийн явц',
                      style: TextStyle(
                        fontSize: context.rFontSize(15),
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedCount / $totalCount',
                      style: TextStyle(
                        fontSize: context.rFontSize(15),
                        fontWeight: FontWeight.bold,
                        color: c.brandGreen,
                      ),
                    ),
                  ],
                ),
                context.rHeight(6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.rRadius(4)),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    minHeight: context.rSpacing(6),
                    backgroundColor: c.muted,
                    valueColor: AlwaysStoppedAnimation(c.brandGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
