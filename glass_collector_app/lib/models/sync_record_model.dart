/// Matches backend SyncRecordDto for POST /api/trips/{tripId}/sync.
class SyncRecordModel {
  const SyncRecordModel({
    required this.supplierCode,
    required this.clearKg,
    required this.colouredKg,
    required this.condition,
    required this.collectedAtUtc,
  });

  final String supplierCode;
  final double clearKg;
  final double colouredKg;
  final String condition;
  final DateTime collectedAtUtc;

  factory SyncRecordModel.fromJson(Map<String, dynamic> json) {
    return SyncRecordModel(
      supplierCode: json['supplierCode'] as String,
      clearKg: (json['clearKg'] as num).toDouble(),
      colouredKg: (json['colouredKg'] as num).toDouble(),
      condition: json['condition'] as String,
      collectedAtUtc: DateTime.parse(json['collectedAtUtc'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'supplierCode': supplierCode,
        'clearKg': clearKg,
        'colouredKg': colouredKg,
        'condition': condition,
        'collectedAtUtc': collectedAtUtc.toUtc().toIso8601String(),
      };
}
