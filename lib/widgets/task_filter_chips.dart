import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class TaskFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const TaskFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        _FilterChip(
          label: 'Бүгд',
          value: 'all',
          selected: selectedFilter,
          c: c,
          onTap: () => onFilterChanged('all'),
        ),
        SizedBox(width: context.rSpacing(8)),
        _FilterChip(
          label: 'Хүлээгдэж буй',
          value: 'pending',
          selected: selectedFilter,
          c: c,
          color: c.warningOrange,
          onTap: () => onFilterChanged('pending'),
        ),
        SizedBox(width: context.rSpacing(8)),
        _FilterChip(
          label: 'Явагдаж буй',
          value: 'inProgress',
          selected: selectedFilter,
          c: c,
          color: c.info,
          onTap: () => onFilterChanged('inProgress'),
        ),
        SizedBox(width: context.rSpacing(8)),
        _FilterChip(
          label: 'Дууссан',
          value: 'completed',
          selected: selectedFilter,
          c: c,
          color: c.success,
          onTap: () => onFilterChanged('completed'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final AppColorScheme c;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.c,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final activeColor = color ?? c.brandGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: context.rSymmetricPadding(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : c.cardBackground,
          borderRadius: BorderRadius.circular(context.rRadius(10)),
          border: Border.all(
            color: isSelected ? activeColor : c.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.rFontSize(13),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : c.mutedForeground,
          ),
        ),
      ),
    );
  }
}
