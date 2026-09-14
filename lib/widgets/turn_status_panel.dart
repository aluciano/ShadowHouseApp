import 'package:flutter/material.dart';

enum TurnStatusKind { active, waiting, resolving }

class TurnStatusPanel extends StatelessWidget {
  const TurnStatusPanel({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final TurnStatusKind kind;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isActive = kind == TurnStatusKind.active;
    final color = switch (kind) {
      TurnStatusKind.active => const Color(0xFFE7C76F),
      TurnStatusKind.waiting => Colors.white60,
      TurnStatusKind.resolving => const Color(0xFFE4A8FF),
    };
    final icon = switch (kind) {
      TurnStatusKind.active => Icons.play_arrow,
      TurnStatusKind.waiting => Icons.hourglass_top,
      TurnStatusKind.resolving => Icons.auto_fix_high,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF342015) : const Color(0xFF221229),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: isActive ? 2 : 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
