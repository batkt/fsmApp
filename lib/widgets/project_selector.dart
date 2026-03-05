import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

class ProjectSelector extends StatelessWidget {
  final bool isLoading;
  final List<Project> projects;
  final String? selectedProjectId;
  final Project? currentProject;
  final void Function(String) onProjectSelected;

  const ProjectSelector({
    super.key,
    required this.isLoading,
    required this.projects,
    required this.selectedProjectId,
    required this.currentProject,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: c.brandGreen),
      );
    }

    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    final name = selectedProjectId == 'all' ? 'Бүх төсөл' : (currentProject?.ner ?? 'Төсөл');

    return GestureDetector(
      onTap: () => _showProjectModal(context, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.brandGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.brandGreen.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_rounded, size: 16, color: c.brandGreen),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.brandGreen,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: c.brandGreen,
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectModal(BuildContext context, AppColorScheme c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final mc = ctx.colors;
        return Container(
          decoration: BoxDecoration(
            color: mc.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mc.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: mc.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_city_rounded,
                          color: mc.brandGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Төсөл сонгох',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mc.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${projects.length} төсөл олдлоо',
                              style: TextStyle(
                                fontSize: 13,
                                color: mc.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // "All Projects" option
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onProjectSelected('all');
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selectedProjectId == 'all'
                                ? mc.brandGreen.withOpacity(0.08)
                                : mc.muted.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedProjectId == 'all'
                                  ? mc.brandGreen.withOpacity(0.4)
                                  : mc.border.withOpacity(0.3),
                              width: selectedProjectId == 'all' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: selectedProjectId == 'all'
                                      ? mc.brandGreen.withOpacity(0.15)
                                      : mc.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.all_inbox_rounded,
                                  size: 22,
                                  color: selectedProjectId == 'all'
                                      ? mc.brandGreen
                                      : mc.mutedForeground,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Бүх төсөл',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: selectedProjectId == 'all'
                                            ? mc.brandGreen
                                            : mc.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedProjectId == 'all'
                                          ? 'Одоо сонгогдсон'
                                          : 'Нийт даалгаврыг харах',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: selectedProjectId == 'all'
                                            ? mc.brandGreen.withOpacity(0.7)
                                            : mc.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedProjectId == 'all')
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: mc.brandGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...projects.map((project) {
                    final isSelected = project.id == selectedProjectId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            onProjectSelected(project.id);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mc.brandGreen.withOpacity(0.08)
                                  : mc.muted.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? mc.brandGreen.withOpacity(0.4)
                                    : mc.border.withOpacity(0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? mc.brandGreen.withOpacity(0.15)
                                        : mc.muted,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.apartment_rounded,
                                    size: 22,
                                    color: isSelected
                                        ? mc.brandGreen
                                        : mc.mutedForeground,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.ner,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? mc.brandGreen
                                              : mc.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isSelected
                                            ? 'Одоо сонгогдсон'
                                            : project.tuluvLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? mc.brandGreen.withOpacity(0.7)
                                              : mc.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: mc.brandGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
