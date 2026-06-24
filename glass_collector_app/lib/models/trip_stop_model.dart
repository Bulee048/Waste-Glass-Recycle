class TripStopModel {
  const TripStopModel({
    required this.sequenceOrder,
    required this.supplierId,
    required this.supplierCode,
    required this.supplierName,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceFromPreviousKm,
    required this.status,
    required this.expectedClearKg,
    required this.expectedColouredKg,
  });

  final int sequenceOrder;
  final int supplierId;
  final String supplierCode;
  final String supplierName;
  final String? address;
  final double latitude;
  final double longitude;
  final double distanceFromPreviousKm;
  final String status;
  final double expectedClearKg;
  final double expectedColouredKg;

  factory TripStopModel.fromJson(Map<String, dynamic> json) {
    return TripStopModel(
      sequenceOrder: json['sequenceOrder'] as int,
      supplierId: json['supplierId'] as int,
      supplierCode: json['supplierCode'] as String,
      supplierName: json['supplierName'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceFromPreviousKm: (json['distanceFromPreviousKm'] as num).toDouble(),
      status: json['status'] as String,
      expectedClearKg: (json['expectedClearKg'] as num).toDouble(),
      expectedColouredKg: (json['expectedColouredKg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sequenceOrder': sequenceOrder,
        'supplierId': supplierId,
        'supplierCode': supplierCode,
        'supplierName': supplierName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distanceFromPreviousKm': distanceFromPreviousKm,
        'status': status,
        'expectedClearKg': expectedClearKg,
        'expectedColouredKg': expectedColouredKg,
      };

  TripStopModel copyWith({
    int? sequenceOrder,
    int? supplierId,
    String? supplierCode,
    String? supplierName,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceFromPreviousKm,
    String? status,
    double? expectedClearKg,
    double? expectedColouredKg,
  }) {
    return TripStopModel(
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      supplierId: supplierId ?? this.supplierId,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromPreviousKm:
          distanceFromPreviousKm ?? this.distanceFromPreviousKm,
      status: status ?? this.status,
      expectedClearKg: expectedClearKg ?? this.expectedClearKg,
      expectedColouredKg: expectedColouredKg ?? this.expectedColouredKg,
    );
  }
}
