import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_collector_app/models/trip_stop_model.dart';
import 'package:glass_collector_app/models/trip_summary_model.dart';
import 'package:glass_collector_app/providers/scan_collect_provider.dart';

TripSummaryModel _sampleTrip() {
  return TripSummaryModel(
    tripId: 1,
    tripDate: '2026-06-23',
    totalDistanceKm: 12.3,
    remainingStops: 4,
    stops: const [
      TripStopModel(
        sequenceOrder: 1,
        supplierId: 1,
        supplierCode: 'SUP-001',
        supplierName: 'Green Bottle Restaurant',
        address: '42 Galle Road',
        latitude: 6.9,
        longitude: 79.85,
        distanceFromPreviousKm: 0.7,
        status: 'Collected',
        expectedClearKg: 48.5,
        expectedColouredKg: 22,
      ),
      TripStopModel(
        sequenceOrder: 3,
        supplierId: 6,
        supplierCode: 'SUP-006',
        supplierName: 'Harbour Lights Restaurant',
        address: '5 Bristol Street',
        latitude: 6.93,
        longitude: 79.84,
        distanceFromPreviousKm: 1.9,
        status: 'Next',
        expectedClearKg: 65,
        expectedColouredKg: 19.5,
      ),
    ],
  );
}

void main() {
  test('correct scan unlocks form state', () {
    final trip = _sampleTrip();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(scanCollectProvider(trip).notifier);
    notifier.handleScanResult('SUP-006');

    final state = container.read(scanCollectProvider(trip));
    expect(state.scanVerified, isTrue);
    expect(state.scanError, isNull);
  });

  test('wrong scan shows mismatch error and keeps form locked', () {
    final trip = _sampleTrip();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(scanCollectProvider(trip).notifier);
    notifier.handleScanResult('SUP-003');

    final state = container.read(scanCollectProvider(trip));
    expect(state.scanVerified, isFalse);
    expect(
      state.scanError,
      'Wrong supplier. Expected SUP-006, scanned SUP-003.',
    );
  });
}
