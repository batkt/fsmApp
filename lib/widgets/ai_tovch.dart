import 'package:flutter/material.dart';

/// AI-ийн хөвөгч товч — бүх хуудсанд ижил харагдана (градиент + ✨ дүрс).
class AiTovch extends StatelessWidget {
  const AiTovch({super.key, required this.onTap, this.tooltip = 'AI туслах'});
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        shadowColor: const Color(0xFFF18F02).withValues(alpha: 0.5),
        child: Ink(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6B003), Color(0xFFF18F02), Color(0xFF6D5DFC)],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
