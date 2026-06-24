import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collection_request_model.dart';
import '../models/trip_report_model.dart';
import '../models/trip_report_supplier_model.dart';
import '../providers/app_providers.dart';
import '../widgets/loading_indicator.dart';

class TripReportState {
  final TripReportModel? report;
  final List<CollectionRequestModel>? fallbackCollections;
  final bool isOfflineFallback;

  TripReportState({
    this.report,
    this.fallbackCollections,
    required this.isOfflineFallback,
  });
}

final tripReportProvider = FutureProvider.family<TripReportState, int>((
  ref,
  tripId,
) async {
  final api = ref.watch(apiServiceProvider);
  final db = ref.watch(localDbServiceProvider);

  try {
    final report = await api.getTripReport(tripId);
    return TripReportState(report: report, isOfflineFallback: false);
  } catch (e) {
    final collections = await db.getAllCollections();
    final tripCollections = collections
        .where((c) => c.tripId == tripId)
        .toList();
    return TripReportState(
      report: null,
      fallbackCollections: tripCollections,
      isOfflineFallback: true,
    );
  }
});

final syncProvider = AsyncNotifierProvider.autoDispose
    .family<SyncNotifier, void, int>(SyncNotifier.new);

class SyncNotifier extends AsyncNotifier<void> {
  SyncNotifier(this.tripId);

  final int tripId;

  @override
  FutureOr<void> build() {}

  Future<void> sync() async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(localDbServiceProvider);

      final unsynced = await db.getUnsyncedCollections();
      final tripUnsynced = unsynced.where((c) => c.tripId == tripId).toList();

      if (tripUnsynced.isEmpty) {
        state = const AsyncData(null);
        return;
      }

      await api.syncTrip(
        tripId,
        tripUnsynced,
        collectedAtUtcValues: tripUnsynced
            .map((c) => c.collectedAtUtc ?? DateTime.now())
            .toList(),
      );

      for (final r in tripUnsynced) {
        if (r.localId != null) {
          await db.markSynced(r.localId!);
        }
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class TripReportScreen extends ConsumerWidget {
  const TripReportScreen({super.key, required this.tripId});

  final int tripId;

  String _formatDuration(double? minutes) {
    if (minutes == null) return 'N/A';
    final int mins = minutes.round();
    final int h = mins ~/ 60;
    final int m = mins % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  void _showSnackBar(BuildContext context, String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(tripReportProvider(tripId));
    final syncState = ref.watch(syncProvider(tripId));

    ref.listen<AsyncValue<void>>(syncProvider(tripId), (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (prev is AsyncLoading) {
            _showSnackBar(context, 'All records synced successfully', false);
            ref.invalidate(tripReportProvider(tripId));
          }
        },
        error: (err, st) {
          _showSnackBar(
            context,
            'Sync failed — your data is saved locally and will not be lost. Try again when you have a connection.',
            true,
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Report')),
      body: reportAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading report...'),
        error: (err, _) => Center(child: Text('Failed to load report: $err')),
        data: (state) {
          return Column(
            children: [
              Expanded(
                child: state.isOfflineFallback
                    ? _buildFallbackReport(
                        context,
                        state.fallbackCollections ?? [],
                      )
                    : _buildFullReport(context, state.report!),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: syncState.isLoading
                        ? null
                        : () => ref.read(syncProvider(tripId).notifier).sync(),
                    icon: syncState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      syncState.isLoading ? 'Syncing...' : 'Sync to Server',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackReport(
    BuildContext context,
    List<CollectionRequestModel> collections,
  ) {
    final totalClear = collections.fold(0.0, (sum, c) => sum + c.clearKg);
    final totalColoured = collections.fold(0.0, (sum, c) => sum + c.colouredKg);
    final totalKg = totalClear + totalColoured;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.offline_bolt, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Offline Mode. Showing locally saved collections.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Collected: ${totalKg.toStringAsFixed(1)} kg',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clear: ${totalClear.toStringAsFixed(1)} kg  |  Coloured: ${totalColoured.toStringAsFixed(1)} kg',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...collections.map(
          (c) => Card(
            child: ListTile(
              title: Text(
                'Supplier: ${c.supplierCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Clear: ${c.clearKg} kg, Coloured: ${c.colouredKg} kg\nCondition: ${c.condition}',
                ),
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullReport(BuildContext context, TripReportModel report) {
    final totalKg = report.totalClearKg + report.totalColouredKg;
    final distanceText = report.totalDistanceKm != null
        ? '${report.totalDistanceKm!.toStringAsFixed(1)} km'
        : 'N/A';
    final durationText = _formatDuration(report.tripDurationMinutes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Collected:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${totalKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '(Clear: ${report.totalClearKg.toStringAsFixed(1)} kg, Coloured: ${report.totalColouredKg.toStringAsFixed(1)} kg)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Distance:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(distanceText),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trip Duration:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(durationText),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Collections by Supplier',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...report.suppliers.map((s) => _buildSupplierCard(context, s)),
      ],
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    TripReportSupplierModel supplier,
  ) {
    final expectedTotal =
        supplier.expectedClearKg + supplier.expectedColouredKg;
    final collectedTotal =
        (supplier.collectedClearKg ?? 0) + (supplier.collectedColouredKg ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supplier.supplierName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expected:'),
                Text(
                  '${expectedTotal.toStringAsFixed(1)} kg (C: ${supplier.expectedClearKg}, Col: ${supplier.expectedColouredKg})',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Collected:'),
                Text(
                  '${collectedTotal.toStringAsFixed(1)} kg (C: ${supplier.collectedClearKg ?? 0}, Col: ${supplier.collectedColouredKg ?? 0})',
                ),
              ],
            ),
            if (supplier.condition != null &&
                supplier.condition!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('Condition:'), Text(supplier.condition!)],
              ),
            ],
            if (supplier.isShortfall) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade800),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Below expected amount',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
