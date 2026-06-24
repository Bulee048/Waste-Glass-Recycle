import '../models/trip_stop_model.dart';
import '../models/trip_summary_model.dart';

/// Offline fallback: mark the collected stop and promote the next pending stop.
TripSummaryModel advanceTripLocally(
  TripSummaryModel trip,
  String collectedSupplierCode,
) {
  var promotedNext = false;
  final updatedStops = trip.stops.map((stop) {
    if (stop.supplierCode == collectedSupplierCode) {
      return stop.copyWith(status: 'Collected');
    }
    if (!promotedNext && stop.status.toLowerCase() == 'pending') {
      promotedNext = true;
      return stop.copyWith(status: 'Next');
    }
    return stop;
  }).toList();

  final remaining = updatedStops
      .where((s) => s.status.toLowerCase() != 'collected')
      .length;

  return TripSummaryModel(
    tripId: trip.tripId,
    tripDate: trip.tripDate,
    totalDistanceKm: trip.totalDistanceKm,
    remainingStops: remaining,
    stops: updatedStops,
  );
}

TripStopModel? findNextStop(TripSummaryModel trip) {
  for (final stop in trip.stops) {
    if (stop.status.toLowerCase() == 'next') {
      return stop;
    }
  }
  return null;
}

int collectedStopCount(TripSummaryModel trip) {
  return trip.stops
      .where((s) => s.status.toLowerCase() == 'collected')
      .length;
}
