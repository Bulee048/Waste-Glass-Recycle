import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_collector_app/main.dart';
import 'package:glass_collector_app/models/trip_stop_model.dart';
import 'package:glass_collector_app/models/trip_summary_model.dart';
import 'package:glass_collector_app/providers/trip_provider.dart';

void main() {
  testWidgets('app loads trip sequence screen', (WidgetTester tester) async {
    final trip = TripSummaryModel(
      tripId: 1,
      tripDate: '2026-06-23',
      totalDistanceKm: 18.4,
      remainingStops: 4,
      stops: const [
        TripStopModel(
          sequenceOrder: 1,
          supplierId: 1,
          supplierCode: 'SUP-001',
          supplierName: 'Green Bottle Restaurant',
          address: '123 Galle Road, Colombo',
          latitude: 6.9271,
          longitude: 79.8612,
          distanceFromPreviousKm: 0,
          status: 'Collected',
          expectedClearKg: 10,
          expectedColouredKg: 5,
        ),
        TripStopModel(
          sequenceOrder: 2,
          supplierId: 2,
          supplierCode: 'SUP-002',
          supplierName: 'Ocean View Cafe',
          address: '45 Marine Drive, Colombo',
          latitude: 6.93,
          longitude: 79.86,
          distanceFromPreviousKm: 2.1,
          status: 'Next',
          expectedClearKg: 8,
          expectedColouredKg: 4,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripProvider.overrideWith((ref) async => trip),
        ],
        child: const GlassCollectorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Trip"), findsOneWidget);
    expect(find.text('18.4 km total'), findsOneWidget);
    expect(find.text('4 of 2 stops remaining'), findsOneWidget);
    expect(find.text('Start / Continue Collection'), findsOneWidget);
  });
}
