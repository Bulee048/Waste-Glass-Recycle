class CollectionRequestModel {
  const CollectionRequestModel({
    required this.tripId,
    required this.supplierCode,
    required this.clearKg,
    required this.colouredKg,
    required this.condition,
    this.localId,
    this.collectedAtUtc,
    this.synced,
  });

  final int tripId;
  final String supplierCode;
  final double clearKg;
  final double colouredKg;
  final String condition;

  /// Populated when loaded from local SQLite (not sent to the API).
  final int? localId;
  final DateTime? collectedAtUtc;
  final bool? synced;

  factory CollectionRequestModel.fromJson(Map<String, dynamic> json) {
    return CollectionRequestModel(
      tripId: json['tripId'] as int,
      supplierCode: json['supplierCode'] as String,
      clearKg: (json['clearKg'] as num).toDouble(),
      colouredKg: (json['colouredKg'] as num).toDouble(),
      condition: json['condition'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'supplierCode': supplierCode,
        'clearKg': clearKg,
        'colouredKg': colouredKg,
        'condition': condition,
      };

  CollectionRequestModel copyWith({
    int? tripId,
    String? supplierCode,
    double? clearKg,
    double? colouredKg,
    String? condition,
    int? localId,
    DateTime? collectedAtUtc,
    bool? synced,
  }) {
    return CollectionRequestModel(
      tripId: tripId ?? this.tripId,
      supplierCode: supplierCode ?? this.supplierCode,
      clearKg: clearKg ?? this.clearKg,
      colouredKg: colouredKg ?? this.colouredKg,
      condition: condition ?? this.condition,
      localId: localId ?? this.localId,
      collectedAtUtc: collectedAtUtc ?? this.collectedAtUtc,
      synced: synced ?? this.synced,
    );
  }
}
