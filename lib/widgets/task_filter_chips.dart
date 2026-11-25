import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Status tiles that double as filters: each shows its count for the day,
/// the selected one fills with its color.
class TaskFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Map<String, int> counts;

  const TaskFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.counts = const {},
  });

  static const _tiles = [
    ('all', 'Бүгд', Icons.layers_rounded, [Color(0xFF5B8DEF), Color(0xFF315BB0)]),
    ('pending', 'Хүлээгдэж', Icons.schedule_rounded, [Color(0xFFFBBF24), Color(0xFFF97316)]),
    ('inProgress', 'Явагдаж', Icons.play_circle_outline_rounded, [Color(0xFF38BDF8), Color(0xFF2563EB)]),
    ('completed', 'Дууссан', Icons.check_circle_outline_rounded, [Color(0xFF34D399), Color(0xFF059669)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _tiles.length; i++) ...[
          if (i > 0) SizedBox(width: context.rSpacing(8)),
          Expanded(
            child: _StatTile(
              label: _tiles[i].$2,
              icon: _tiles[i].$3,
              gradient: _tiles[i].$4,
              count: counts[_tiles[i].$1] ?? 0,
              selected: selectedFilter == _tiles[i].$1,
              onTap: () => onFilterChanged(_tiles[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ungu = gradient.last;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: context.rSymmetricPadding(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)
                : null,
            color: selected ? null : ungu.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(context.rRadius(16)),
            boxShadow: selected
                ? [BoxShadow(color: ungu.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: context.rIconSize(16), color: selected ? Colors.white : ungu),
                  const Spacer(),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: context.rFontSize(18),
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : c.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              context.rHeight(4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rFontSize(11.5),
                  color: selected ? Colors.white.withValues(alpha: 0.9) : c.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
