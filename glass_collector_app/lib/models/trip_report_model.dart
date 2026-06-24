import 'trip_report_supplier_model.dart';

class TripReportModel {
  const TripReportModel({
    required this.tripId,
    required this.tripDate,
    this.totalDistanceKm,
    this.tripDurationMinutes,
    required this.totalClearKg,
    required this.totalColouredKg,
    required this.suppliers,
  });

  final int tripId;
  final String tripDate;
  final double? totalDistanceKm;
  final double? tripDurationMinutes;
  final double totalClearKg;
  final double totalColouredKg;
  final List<TripReportSupplierModel> suppliers;

  factory TripReportModel.fromJson(Map<String, dynamic> json) {
    return TripReportModel(
      tripId: json['tripId'] as int,
      tripDate: json['tripDate'] as String,
      totalDistanceKm: json['totalDistanceKm'] == null
          ? null
          : (json['totalDistanceKm'] as num).toDouble(),
      tripDurationMinutes: json['tripDurationMinutes'] == null
          ? null
          : (json['tripDurationMinutes'] as num).toDouble(),
      totalClearKg: (json['totalClearKg'] as num).toDouble(),
      totalColouredKg: (json['totalColouredKg'] as num).toDouble(),
      suppliers: (json['suppliers'] as List<dynamic>)
          .map(
            (e) => TripReportSupplierModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'tripDate': tripDate,
        'totalDistanceKm': totalDistanceKm,
        'tripDurationMinutes': tripDurationMinutes,
        'totalClearKg': totalClearKg,
        'totalColouredKg': totalColouredKg,
        'suppliers': suppliers.map((s) => s.toJson()).toList(),
      };
}
