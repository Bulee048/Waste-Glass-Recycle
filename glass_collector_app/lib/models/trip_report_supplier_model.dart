class TripReportSupplierModel {
  const TripReportSupplierModel({
    required this.supplierCode,
    required this.supplierName,
    required this.expectedClearKg,
    required this.expectedColouredKg,
    this.collectedClearKg,
    this.collectedColouredKg,
    this.condition,
    required this.isShortfall,
    required this.status,
  });

  final String supplierCode;
  final String supplierName;
  final double expectedClearKg;
  final double expectedColouredKg;
  final double? collectedClearKg;
  final double? collectedColouredKg;
  final String? condition;
  final bool isShortfall;
  final String status;

  factory TripReportSupplierModel.fromJson(Map<String, dynamic> json) {
    return TripReportSupplierModel(
      supplierCode: json['supplierCode'] as String,
      supplierName: json['supplierName'] as String,
      expectedClearKg: (json['expectedClearKg'] as num).toDouble(),
      expectedColouredKg: (json['expectedColouredKg'] as num).toDouble(),
      collectedClearKg: json['collectedClearKg'] == null
          ? null
          : (json['collectedClearKg'] as num).toDouble(),
      collectedColouredKg: json['collectedColouredKg'] == null
          ? null
          : (json['collectedColouredKg'] as num).toDouble(),
      condition: json['condition'] as String?,
      isShortfall: json['isShortfall'] as bool,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'supplierCode': supplierCode,
        'supplierName': supplierName,
        'expectedClearKg': expectedClearKg,
        'expectedColouredKg': expectedColouredKg,
        'collectedClearKg': collectedClearKg,
        'collectedColouredKg': collectedColouredKg,
        'condition': condition,
        'isShortfall': isShortfall,
        'status': status,
      };
}
