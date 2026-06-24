import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/trip_summary_model.dart';
import '../providers/trip_provider.dart';
import '../services/api_exception.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/trip_stop_card.dart';
import 'scan_collect_screen.dart';
import 'trip_report_screen.dart';

class TripSequenceScreen extends ConsumerWidget {
  const TripSequenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Trip"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(tripProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: tripAsync.when(
        loading: () => const LoadingIndicator(
          message: 'Loading today\'s route…',
        ),
        error: (error, _) => _TripErrorView(
          message: _friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(tripProvider),
        ),
        data: (trip) => _TripContent(trip: trip),
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return "Couldn't reach the server. Check your connection and try again.";
  }
}

class _TripErrorView extends StatelessWidget {
  const _TripErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripContent extends ConsumerWidget {
  const _TripContent({required this.trip});

  final TripSummaryModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalStops = trip.stops.length;
    final distanceText = trip.totalDistanceKm == null
        ? 'Route distance pending'
        : '${NumberFormat('#0.0').format(trip.totalDistanceKm)} km total';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        distanceText,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${trip.remainingStops} of $totalStops stops remaining',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trip date: ${trip.tripDate}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Route sequence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...trip.stops.map(
                (stop) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TripStopCard(stop: stop),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: trip.remainingStops > 0
                ? FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanCollectScreen(trip: trip),
                        ),
                      );
                      ref.invalidate(tripProvider);
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Start / Continue Collection'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripReportScreen(tripId: trip.tripId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.summarize),
                    label: const Text('View Trip Report'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
