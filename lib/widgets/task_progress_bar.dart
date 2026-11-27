import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Day progress: gradient bar + "x / y дууссан".
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
    final khuvi = completedCount / totalCount;
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Container(
              height: context.rSpacing(8),
              decoration: BoxDecoration(
                color: c.brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: box.maxWidth * khuvi,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
                ),
              ),
            ),
          ),
        ),
        context.rWidth(10),
        Text(
          '$completedCount / $totalCount дууссан',
          style: TextStyle(
            fontSize: context.rFontSize(12.5),
            color: c.mutedForeground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
