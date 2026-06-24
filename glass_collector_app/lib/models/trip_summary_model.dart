import 'trip_stop_model.dart';

class TripSummaryModel {
  const TripSummaryModel({
    required this.tripId,
    required this.tripDate,
    this.totalDistanceKm,
    required this.remainingStops,
    required this.stops,
  });

  final int tripId;
  final String tripDate;
  final double? totalDistanceKm;
  final int remainingStops;
  final List<TripStopModel> stops;

  factory TripSummaryModel.fromJson(Map<String, dynamic> json) {
    return TripSummaryModel(
      tripId: json['tripId'] as int,
      tripDate: json['tripDate'] as String,
      totalDistanceKm: json['totalDistanceKm'] == null
          ? null
          : (json['totalDistanceKm'] as num).toDouble(),
      remainingStops: json['remainingStops'] as int,
      stops: (json['stops'] as List<dynamic>)
          .map((e) => TripStopModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'tripDate': tripDate,
        'totalDistanceKm': totalDistanceKm,
        'remainingStops': remainingStops,
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}
