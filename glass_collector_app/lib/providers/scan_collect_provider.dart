import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collection_request_model.dart';
import '../models/trip_stop_model.dart';
import '../models/trip_summary_model.dart';
import '../utils/trip_advance.dart';
import 'app_providers.dart';
import 'trip_provider.dart';

class ScanCollectState {
  const ScanCollectState({
    required this.trip,
    this.scanVerified = false,
    this.scanError,
    this.showScanSuccess = false,
    this.isSubmitting = false,
  });

  final TripSummaryModel trip;
  final bool scanVerified;
  final String? scanError;
  final bool showScanSuccess;
  final bool isSubmitting;

  TripStopModel? get currentStop => findNextStop(trip);

  bool get isTripComplete => currentStop == null;

  int get progressIndex {
    final next = currentStop;
    if (next != null) {
      return next.sequenceOrder;
    }
    return trip.stops.length;
  }

  ScanCollectState copyWith({
    TripSummaryModel? trip,
    bool? scanVerified,
    String? scanError,
    bool clearScanError = false,
    bool? showScanSuccess,
    bool? isSubmitting,
  }) {
    return ScanCollectState(
      trip: trip ?? this.trip,
      scanVerified: scanVerified ?? this.scanVerified,
      scanError: clearScanError ? null : scanError ?? this.scanError,
      showScanSuccess: showScanSuccess ?? this.showScanSuccess,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final scanCollectProvider = NotifierProvider.autoDispose
    .family<ScanCollectController, ScanCollectState, TripSummaryModel>(
      ScanCollectController.new,
    );

class ScanCollectController extends Notifier<ScanCollectState> {
  ScanCollectController(this.trip);

  final TripSummaryModel trip;

  @override
  ScanCollectState build() {
    return ScanCollectState(trip: trip);
  }

  void handleScanResult(String scannedRaw) {
    final stop = state.currentStop;
    if (stop == null) {
      return;
    }

    final scanned = scannedRaw.trim();
    final expected = stop.supplierCode.trim();

    if (scanned.toUpperCase() == expected.toUpperCase()) {
      state = state.copyWith(
        scanVerified: true,
        clearScanError: true,
        showScanSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      scanVerified: false,
      scanError: 'Wrong supplier. Expected $expected, scanned $scanned.',
      showScanSuccess: false,
    );
  }

  void clearScanSuccess() {
    if (state.showScanSuccess) {
      state = state.copyWith(showScanSuccess: false);
    }
  }

  void clearScanError() {
    if (state.scanError != null) {
      state = state.copyWith(clearScanError: true);
    }
  }

  /// Returns `true` when the trip is complete and Screen 3 should open.
  Future<({bool tripComplete, bool syncedToServer})> confirmCollection({
    required double clearKg,
    required double colouredKg,
    required String condition,
  }) async {
    final stop = state.currentStop;
    if (stop == null || !state.scanVerified) {
      return (tripComplete: state.isTripComplete, syncedToServer: false);
    }

    state = state.copyWith(isSubmitting: true);

    final record = CollectionRequestModel(
      tripId: state.trip.tripId,
      supplierCode: stop.supplierCode,
      clearKg: clearKg,
      colouredKg: colouredKg,
      condition: condition,
    );

    final localDb = ref.read(localDbServiceProvider);
    final collectedAt = DateTime.now().toUtc();
    final localId = await localDb.insertCollection(
      record,
      collectedAtUtc: collectedAt,
    );

    var syncedToServer = false;
    try {
      await ref.read(apiServiceProvider).submitCollection(record);
      await localDb.markSynced(localId);
      syncedToServer = true;
    } catch (error, stackTrace) {
      debugPrint(
        'Collection saved locally; API sync deferred: $error\n$stackTrace',
      );
    }

    TripSummaryModel updatedTrip;
    if (syncedToServer) {
      ref.invalidate(tripProvider);
      try {
        updatedTrip = await ref.read(tripProvider.future);
      } catch (_) {
        updatedTrip = advanceTripLocally(state.trip, stop.supplierCode);
      }
    } else {
      updatedTrip = advanceTripLocally(state.trip, stop.supplierCode);
    }

    final tripComplete = findNextStop(updatedTrip) == null;
    state = ScanCollectState(trip: updatedTrip);

    return (tripComplete: tripComplete, syncedToServer: syncedToServer);
  }
}
