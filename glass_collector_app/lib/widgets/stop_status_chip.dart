import 'package:flutter/material.dart';

class StopStatusChip extends StatelessWidget {
  const StopStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    late final Color background;
    late final Color foreground;
    late final IconData? icon;
    late final String label;

    switch (normalized) {
      case 'collected':
        background = Colors.green.shade100;
        foreground = Colors.green.shade800;
        icon = Icons.check_circle;
        label = 'Collected';
      case 'next':
        background = Colors.blue.shade100;
        foreground = Colors.blue.shade800;
        icon = Icons.navigation;
        label = 'Next';
      default:
        background = Colors.grey.shade200;
        foreground = Colors.grey.shade800;
        icon = null;
        label = 'Pending';
    }

    return Chip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 18, color: foreground),
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
