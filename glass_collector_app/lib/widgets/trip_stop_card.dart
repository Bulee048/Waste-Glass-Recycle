import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip_stop_model.dart';
import 'stop_status_chip.dart';

class TripStopCard extends StatelessWidget {
  const TripStopCard({super.key, required this.stop});

  final TripStopModel stop;

  @override
  Widget build(BuildContext context) {
    final distance = NumberFormat('#0.0').format(stop.distanceFromPreviousKm);
    final theme = Theme.of(context);

    return Card(
      elevation: stop.status.toLowerCase() == 'next' ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: stop.status.toLowerCase() == 'next'
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Stop ${stop.sequenceOrder}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StopStatusChip(status: stop.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stop.supplierName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (stop.address != null && stop.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                stop.address!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.route,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text('$distance km from previous stop'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stop.supplierCode,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
