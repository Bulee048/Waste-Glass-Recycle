import 'trip_stop_model.dart';

class CollectionResultModel {
  const CollectionResultModel({
    required this.updatedStop,
    this.nextStop,
    required this.tripCompleted,
  });

  final TripStopModel updatedStop;
  final TripStopModel? nextStop;
  final bool tripCompleted;

  factory CollectionResultModel.fromJson(Map<String, dynamic> json) {
    return CollectionResultModel(
      updatedStop: TripStopModel.fromJson(
        json['updatedStop'] as Map<String, dynamic>,
      ),
      nextStop: json['nextStop'] == null
          ? null
          : TripStopModel.fromJson(json['nextStop'] as Map<String, dynamic>),
      tripCompleted: json['tripCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'updatedStop': updatedStop.toJson(),
        'nextStop': nextStop?.toJson(),
        'tripCompleted': tripCompleted,
      };
}
